use std::sync::{Arc, RwLock};
use anyhow::{Context, Result};
use candle_core::{Device, Tensor};
use candle_transformers::models::bert::{BertModel, Config as BertConfig, HiddenAct, PositionEmbeddingType};
use tokenizers::Tokenizer;
use tracing::{info, warn};

pub const VECTOR_DIMENSION: usize = 384;

/// Native Pure-Rust Candle Bert Model Runner
struct CandleBertEmbedder {
    model: BertModel,
    tokenizer: Tokenizer,
    device: Device,
}

impl CandleBertEmbedder {
    pub fn load_from_bytes(weights_bytes: &[u8], tokenizer_bytes: &[u8], config_bytes: Option<&[u8]>) -> Result<Self> {
        let device = Device::Cpu;

        let tokenizer = Tokenizer::from_bytes(tokenizer_bytes)
            .map_err(|e| anyhow::anyhow!("Failed to parse tokenizer: {}", e))?;

        let config: BertConfig = if let Some(cfg_bytes) = config_bytes {
            serde_json::from_slice(cfg_bytes).context("Failed to parse bert config")?
        } else {
            // Default MiniLM-L6-v2 / BGE-small config
            BertConfig {
                vocab_size: 30522,
                hidden_size: 384,
                num_hidden_layers: 6,
                num_attention_heads: 12,
                intermediate_size: 1536,
                hidden_act: HiddenAct::Gelu,
                hidden_dropout_prob: 0.1,
                max_position_embeddings: 512,
                type_vocab_size: 2,
                initializer_range: 0.02,
                layer_norm_eps: 1e-12,
                pad_token_id: 0,
                position_embedding_type: PositionEmbeddingType::Absolute,
                use_cache: true,
                classifier_dropout: None,
                model_type: Some(String::from("bert")),
            }
        };

        let vb = candle_nn::VarBuilder::from_buffered_safetensors(weights_bytes.to_vec(), candle_core::DType::F32, &device)
            .or_else(|_| candle_nn::VarBuilder::from_buffered_safetensors(weights_bytes.to_vec(), candle_core::DType::F16, &device))?;
        let model = BertModel::load(vb, &config)?;

        Ok(Self {
            model,
            tokenizer,
            device,
        })
    }

    pub fn embed(&self, text: &str) -> Result<Vec<f32>> {
        let encoding = self
            .tokenizer
            .encode(text, true)
            .map_err(|e| anyhow::anyhow!("Tokenization error: {}", e))?;

        let tokens = encoding.get_ids().to_vec();
        let attention_mask_vec = encoding.get_attention_mask().to_vec();
        let token_type_ids_vec = encoding.get_type_ids().to_vec();

        let seq_len = tokens.len();
        if seq_len == 0 {
            return Ok(vec![0.0; VECTOR_DIMENSION]);
        }

        let token_ids = Tensor::from_vec(tokens, (1, seq_len), &self.device)?;
        let token_type_ids = Tensor::from_vec(token_type_ids_vec, (1, seq_len), &self.device)?;
        let attention_mask = Tensor::from_vec(
            attention_mask_vec.iter().map(|&v| v as u32).collect::<Vec<_>>(),
            (1, seq_len),
            &self.device,
        )?;

        // Forward pass
        let embeddings = self.model.forward(&token_ids, &token_type_ids, Some(&attention_mask))?;

        // Mean pooling over token embeddings weighted by attention mask
        let mask_f32 = Tensor::from_vec(
            attention_mask_vec.iter().map(|&v| v as f32).collect::<Vec<_>>(),
            (1, seq_len, 1),
            &self.device,
        )?;

        let sum_embeddings = (embeddings.to_dtype(candle_core::DType::F32)?.broadcast_mul(&mask_f32))?.sum(1)?;
        let sum_mask = mask_f32.sum(1)?.clamp(1e-9, f64::MAX)?;
        let mean_pooled = sum_embeddings.broadcast_div(&sum_mask)?;

        // L2 Normalization
        let norm = mean_pooled.sqr()?.sum_keepdim(1)?.sqrt()?;
        let normalized = mean_pooled.broadcast_div(&norm)?;

        let vector: Vec<f32> = normalized.to_dtype(candle_core::DType::F32)?.squeeze(0)?.to_vec1()?;
        Ok(vector)
    }
}

static CANDLE_ENGINE: RwLock<Option<Arc<CandleBertEmbedder>>> = RwLock::new(None);

/// Pure Rust Vector Embedding Service
pub struct EmbeddingService;

impl EmbeddingService {
    /// Initializes the Candle transformer engine with model bytes.
    pub fn init_model(weights_bytes: &[u8], tokenizer_bytes: &[u8], config_bytes: Option<&[u8]>) -> Result<()> {
        match CandleBertEmbedder::load_from_bytes(weights_bytes, tokenizer_bytes, config_bytes) {
            Ok(embedder) => {
                let mut lock = CANDLE_ENGINE.write().unwrap();
                *lock = Some(Arc::new(embedder));
                info!("Candle native Bert embedder initialized successfully.");
                Ok(())
            }
            Err(e) => {
                warn!("Failed to initialize Candle Bert embedder: {}. Falling back to subword hash projection.", e);
                Err(e)
            }
        }
    }

    /// Computes a normalized 384-dimensional semantic embedding vector for the given text.
    pub fn embed_text(text: &str) -> Vec<f32> {
        let clean = text.trim();
        if clean.is_empty() {
            return vec![0.0; VECTOR_DIMENSION];
        }

        // Try Candle ML model if initialized
        if let Ok(lock) = CANDLE_ENGINE.read() {
            if let Some(ref embedder) = *lock {
                if let Ok(vec) = embedder.embed(clean) {
                    if vec.len() == VECTOR_DIMENSION {
                        return vec;
                    }
                }
            }
        }

        // Deterministic subword hash projection fallback
        Self::fallback_subword_embed(clean)
    }

    /// Deterministic fast subword n-gram hash projection (384 dimensions).
    fn fallback_subword_embed(text: &str) -> Vec<f32> {
        let clean = text.to_lowercase();
        let mut vector = vec![0.0f32; VECTOR_DIMENSION];
        let words: Vec<&str> = clean.split_whitespace().collect();

        for (word_idx, word) in words.iter().enumerate() {
            let word_weight = 1.0 / (1.0 + (word_idx as f32) * 0.1);
            let chars: Vec<char> = word.chars().collect();

            // Word-level hash projection
            let word_hash = Self::fnv1a_hash(word.as_bytes());
            let primary_dim = (word_hash as usize) % VECTOR_DIMENSION;
            let sign = if (word_hash >> 16) & 1 == 0 { 1.0 } else { -1.0 };
            vector[primary_dim] += sign * 2.0 * word_weight;

            // Character n-gram projections (lengths 2 to 4)
            for n in 2..=4 {
                if chars.len() >= n {
                    for window in chars.windows(n) {
                        let ngram: String = window.iter().collect();
                        let ngram_hash = Self::fnv1a_hash(ngram.as_bytes());
                        let dim = (ngram_hash as usize) % VECTOR_DIMENSION;
                        let s = if (ngram_hash >> 8) & 1 == 0 { 1.0 } else { -1.0 };
                        vector[dim] += s * 0.5 * word_weight;
                    }
                }
            }
        }

        // L2 Normalization
        let norm: f32 = vector.iter().map(|v| v * v).sum::<f32>().sqrt();
        if norm > 0.0 {
            for v in vector.iter_mut() {
                *v /= norm;
            }
        }

        vector
    }

    /// Computes cosine similarity between two float vectors.
    #[inline]
    pub fn cosine_similarity(a: &[f32], b: &[f32]) -> f32 {
        cosine_similarity(a, b)
    }

    #[inline]
    fn fnv1a_hash(bytes: &[u8]) -> u64 {
        let mut hash: u64 = 0xcbf29ce484222325;
        for &byte in bytes {
            hash ^= byte as u64;
            hash = hash.wrapping_mul(0x100000001b3);
        }
        hash
    }
}

/// Standalone mathematical utility: computes cosine similarity between two float vectors.
#[inline]
pub fn cosine_similarity(a: &[f32], b: &[f32]) -> f32 {
    if a.len() != b.len() || a.is_empty() {
        return 0.0;
    }

    let mut dot = 0.0f32;
    let mut norm_a = 0.0f32;
    let mut norm_b = 0.0f32;

    for (x, y) in a.iter().zip(b.iter()) {
        dot += x * y;
        norm_a += x * x;
        norm_b += y * y;
    }

    let denom = norm_a.sqrt() * norm_b.sqrt();
    if denom == 0.0 {
        0.0
    } else {
        (dot / denom).clamp(-1.0, 1.0)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_embed_dimension_and_normalization() {
        let v1 = EmbeddingService::embed_text("contradicts");
        assert_eq!(v1.len(), VECTOR_DIMENSION);

        let norm: f32 = v1.iter().map(|x| x * x).sum::<f32>().sqrt();
        assert!((norm - 1.0).abs() < 1e-4, "Vector must be L2 normalized to 1.0, got {}", norm);
    }

    #[test]
    fn test_similarity_ranking() {
        let v_contra = EmbeddingService::embed_text("contradicts");
        let v_contradict = EmbeddingService::embed_text("contradict");
        let v_apple = EmbeddingService::embed_text("apple");

        let sim_same = EmbeddingService::cosine_similarity(&v_contra, &v_contradict);
        let sim_diff = EmbeddingService::cosine_similarity(&v_contra, &v_apple);

        assert!(sim_same > sim_diff, "Similar stems should have higher similarity: {} vs {}", sim_same, sim_diff);
    }
}
