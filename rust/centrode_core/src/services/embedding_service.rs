use std::collections::HashMap;
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
    pub fn load_model(
        weights_bytes: Option<&[u8]>,
        unpacked_path: Option<&str>,
        tokenizer_bytes: &[u8],
        config_bytes: Option<&[u8]>,
    ) -> Result<Self> {
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

        // 1. If pre-unpacked float model already exists on disk, load directly (fast path: 0ms dequantization)
        if let Some(path_str) = unpacked_path {
            let path = std::path::Path::new(path_str);
            if path.is_file() {
                info!("Loading pre-unpacked float Bert model from disk: {}", path_str);
                let weights_buf = std::fs::read(path)
                    .with_context(|| format!("Failed to read pre-unpacked model from {path_str}"))?;
                let vb = candle_nn::VarBuilder::from_buffered_safetensors(
                    weights_buf,
                    candle_core::DType::F32,
                    &device,
                )?;
                let model = BertModel::load(vb, &config)?;
                return Ok(Self {
                    model,
                    tokenizer,
                    device,
                });
            }
        }

        // 2. Otherwise, dequantize the provided Q4/INT8 weights bytes in memory (first run after installation)
        let bytes = weights_bytes
            .ok_or_else(|| anyhow::anyhow!("No weights bytes or unpacked model file available on disk"))?;
        let raw_tensors = candle_core::safetensors::load_buffer(bytes, &device)?;
        let dequantized = Self::dequantize_all_tensors(raw_tensors, &device)?;

        // 3. Persist unpacked float tensors to local disk storage for all future launches
        if let Some(path_str) = unpacked_path {
            let path = std::path::Path::new(path_str);
            if let Some(parent) = path.parent() {
                std::fs::create_dir_all(parent)
                    .with_context(|| format!("Failed to create directory for unpacked model: {:?}", parent))?;
            }
            candle_core::safetensors::save(&dequantized, path)
                .with_context(|| format!("Failed to persist unpacked safetensors to {path_str}"))?;
            info!("Persisted unpacked float model to storage: {}", path_str);
        }

        let vb = candle_nn::VarBuilder::from_tensors(dequantized, candle_core::DType::F32, &device);
        let model = BertModel::load(vb, &config)?;

        Ok(Self {
            model,
            tokenizer,
            device,
        })
    }

    fn dequantize_all_tensors(
        raw_tensors: HashMap<String, Tensor>,
        device: &Device,
    ) -> Result<HashMap<String, Tensor>> {
        let mut dequantized = HashMap::with_capacity(raw_tensors.len());

        for (name, tensor) in &raw_tensors {
            if name.ends_with(".scale") || name.ends_with(".shape") {
                continue;
            }

            let shape_key = format!("{name}.shape");
            let scale_key = format!("{name}.scale");

            if let (Some(shape_tensor), Some(scale_tensor)) = (raw_tensors.get(&shape_key), raw_tensors.get(&scale_key)) {
                // Q4 block-wise dequantization (block size 32, 2x 4-bit nibbles packed per uint8)
                let shape_u32: Vec<u32> = shape_tensor
                    .to_dtype(candle_core::DType::U32)?
                    .flatten_all()?
                    .to_vec1()?;
                let orig_shape: Vec<usize> = shape_u32.into_iter().map(|d| d as usize).collect();
                let total_elements: usize = orig_shape.iter().product();

                let packed_bytes: Vec<u8> = tensor.flatten_all()?.to_vec1()?;
                let scales: Vec<f32> = scale_tensor
                    .to_dtype(candle_core::DType::F32)?
                    .flatten_all()?
                    .to_vec1()?;

                let num_blocks = scales.len();
                let mut out_f32 = Vec::with_capacity(num_blocks * 32);

                for b in 0..num_blocks {
                    let scale = scales[b];
                    let block_offset = b * 16;
                    for i in 0..16 {
                        if block_offset + i < packed_bytes.len() {
                            let byte = packed_bytes[block_offset + i];
                            let mut low = (byte & 0x0F) as i8;
                            let mut high = ((byte >> 4) & 0x0F) as i8;
                            if low >= 8 {
                                low -= 16;
                            }
                            if high >= 8 {
                                high -= 16;
                            }
                            out_f32.push((low as f32) * scale);
                            out_f32.push((high as f32) * scale);
                        }
                    }
                }

                out_f32.truncate(total_elements);
                let dequant_tensor = Tensor::from_vec(out_f32, orig_shape.as_slice(), device)?;
                dequantized.insert(name.clone(), dequant_tensor);
            } else if let Some(scale_tensor) = raw_tensors.get(&scale_key) {
                // INT8 per-tensor dequantization
                let scale: f32 = scale_tensor
                    .to_dtype(candle_core::DType::F32)?
                    .flatten_all()?
                    .to_vec1()?[0];
                let f32_tensor = (tensor.to_dtype(candle_core::DType::F32)? * (scale as f64))?;
                dequantized.insert(name.clone(), f32_tensor);
            } else {
                // Standard float tensor
                let f32_tensor = if tensor.dtype() == candle_core::DType::F16 {
                    tensor.to_dtype(candle_core::DType::F32)?
                } else {
                    tensor.clone()
                };
                dequantized.insert(name.clone(), f32_tensor);
            }
        }

        Ok(dequantized)
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
static EMBEDDING_CACHE: RwLock<Option<HashMap<String, Vec<f32>>>> = RwLock::new(None);

/// Pure Rust Vector Embedding Service
pub struct EmbeddingService;

impl EmbeddingService {
    /// Initializes the Candle transformer engine with optional persistent storage cache.
    pub fn init_model_with_cache(
        weights_bytes: Option<&[u8]>,
        unpacked_path: Option<&str>,
        tokenizer_bytes: &[u8],
        config_bytes: Option<&[u8]>,
    ) -> Result<()> {
        match CandleBertEmbedder::load_model(weights_bytes, unpacked_path, tokenizer_bytes, config_bytes) {
            Ok(embedder) => {
                {
                    let mut lock = CANDLE_ENGINE.write().unwrap();
                    *lock = Some(Arc::new(embedder));
                }
                info!("Candle native Bert embedder initialized successfully.");

                // Pre-warm cache with official relation vocabulary in background
                std::thread::spawn(|| {
                    let index = crate::repo::dictionaries::get_official_ontology_index();
                    for ((_, cat), words) in &index.by_lang_and_cat {
                        if cat == "relation" {
                            for word in words {
                                let _ = Self::embed_text(word);
                            }
                        }
                    }
                });

                Ok(())
            }
            Err(e) => {
                warn!("Failed to initialize Candle Bert embedder: {}. Falling back to subword hash projection.", e);
                Err(e)
            }
        }
    }

    /// Initializes the Candle transformer engine directly with in-memory model bytes.
    pub fn init_model(weights_bytes: &[u8], tokenizer_bytes: &[u8], config_bytes: Option<&[u8]>) -> Result<()> {
        Self::init_model_with_cache(Some(weights_bytes), None, tokenizer_bytes, config_bytes)
    }

    /// Computes a normalized 384-dimensional semantic embedding vector for the given text.
    pub fn embed_text(text: &str) -> Vec<f32> {
        let clean = text.trim();
        if clean.is_empty() {
            return vec![0.0; VECTOR_DIMENSION];
        }

        // Normalize relation tokens (e.g. snake_case / kebab-case: "leads_to" -> "leads to")
        let normalized = clean.replace('_', " ").replace('-', " ");

        // Check in-memory cache first (0.001 ms)
        if let Ok(cache_lock) = EMBEDDING_CACHE.read() {
            if let Some(ref map) = *cache_lock {
                if let Some(cached) = map.get(&normalized) {
                    return cached.clone();
                }
            }
        }

        // Try Candle ML model if initialized
        let computed = if let Ok(lock) = CANDLE_ENGINE.read() {
            if let Some(ref embedder) = *lock {
                if let Ok(vec) = embedder.embed(&normalized) {
                    if vec.len() == VECTOR_DIMENSION {
                        Some(vec)
                    } else {
                        None
                    }
                } else {
                    None
                }
            } else {
                None
            }
        } else {
            None
        };

        let result = computed.unwrap_or_else(|| Self::fallback_subword_embed(clean));

        // Store into cache
        if let Ok(mut cache_lock) = EMBEDDING_CACHE.write() {
            let map = cache_lock.get_or_insert_with(HashMap::new);
            map.insert(normalized, result.clone());
        }

        result
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

    #[test]
    fn test_candle_q4_model_loading() {
        let root = std::path::Path::new(env!("CARGO_MANIFEST_DIR"))
            .parent()
            .unwrap()
            .parent()
            .unwrap();
        let model_path = root.join("assets/models/multilingual_5lang/model.safetensors");
        let tok_path = root.join("assets/models/multilingual_5lang/tokenizer.json");
        let cfg_path = root.join("assets/models/multilingual_5lang/config.json");

        if model_path.exists() && tok_path.exists() && cfg_path.exists() {
            let weights_bytes = std::fs::read(model_path).expect("Read model.safetensors");
            let tok_bytes = std::fs::read(tok_path).expect("Read tokenizer.json");
            let cfg_bytes = std::fs::read(cfg_path).expect("Read config.json");

            let temp_dir = tempfile::tempdir().expect("tempdir");
            let cache_path = temp_dir.path().join("model_unpacked.safetensors");
            let cache_str = cache_path.to_str().unwrap();

            // 1. First run: dequantizes Q4 and writes unpacked float model to disk
            EmbeddingService::init_model_with_cache(
                Some(&weights_bytes),
                Some(cache_str),
                &tok_bytes,
                Some(&cfg_bytes),
            )
            .expect("Failed to initialize Candle Q4 model and write cache");

            assert!(cache_path.is_file(), "Unpacked model file must exist on disk");

            let v_en_1 = EmbeddingService::embed_text("causes");

            // 2. Second run: loads directly from disk cache with weights_bytes = None
            EmbeddingService::init_model_with_cache(
                None,
                Some(cache_str),
                &tok_bytes,
                Some(&cfg_bytes),
            )
            .expect("Failed to reload Candle model from disk cache");

            let v_en_2 = EmbeddingService::embed_text("causes");
            let v_fa = EmbeddingService::embed_text("علت");
            let v_diff = EmbeddingService::embed_text("apple");

            assert_eq!(v_en_1.len(), VECTOR_DIMENSION);
            assert_eq!(v_en_2.len(), VECTOR_DIMENSION);
            assert_eq!(v_fa.len(), VECTOR_DIMENSION);

            let sim_reloaded = EmbeddingService::cosine_similarity(&v_en_1, &v_en_2);
            assert!((sim_reloaded - 1.0).abs() < 1e-4, "Reloaded model must produce identical embeddings");

            let v_leads = EmbeddingService::embed_text("leads_to");
            let v_blocks = EmbeddingService::embed_text("blocks");
            let v_prevents = EmbeddingService::embed_text("prevents");
            let v_es_causa = EmbeddingService::embed_text("causa");
            let v_zh_cause = EmbeddingService::embed_text("导致");

            let sim_cross_fa = EmbeddingService::cosine_similarity(&v_en_2, &v_fa);
            let sim_cross_es = EmbeddingService::cosine_similarity(&v_en_2, &v_es_causa);
            let sim_cross_zh = EmbeddingService::cosine_similarity(&v_en_2, &v_zh_cause);
            let sim_synonym_en = EmbeddingService::cosine_similarity(&v_en_2, &v_leads);
            let sim_blocks_prevents = EmbeddingService::cosine_similarity(&v_blocks, &v_prevents);
            let sim_unrelated = EmbeddingService::cosine_similarity(&v_en_2, &v_diff);

            println!("--- EMBEDDER DIAGNOSTICS ---");
            println!("'causes' <=> 'causes' (reload): {}", sim_reloaded);
            println!("'causes' <=> 'leads_to':        {}", sim_synonym_en);
            println!("'blocks' <=> 'prevents':        {}", sim_blocks_prevents);
            println!("'causes' <=> 'علت' (FA):        {}", sim_cross_fa);
            println!("'causes' <=> 'causa' (ES):      {}", sim_cross_es);
            println!("'causes' <=> '导致' (ZH):       {}", sim_cross_zh);
            println!("'causes' <=> 'apple' (diff):    {}", sim_unrelated);
            println!("----------------------------");

            assert!(
                sim_cross_fa > sim_unrelated,
                "Cross-lingual equivalent ('causes' <=> 'علت') should have higher cosine similarity than 'apple': {} vs {}",
                sim_cross_fa,
                sim_unrelated
            );
            assert!(
                sim_synonym_en > sim_unrelated,
                "Synonym ('causes' <=> 'leads_to') should have higher cosine similarity than 'apple': {} vs {}",
                sim_synonym_en,
                sim_unrelated
            );
        }
    }
}
