use crate::domain::id::TypedRecordId;
use crate::domain::styles::RelationStyle;
use crate::domain::traits::TableKind;
use crate::domain::types::{CustomWord, VectorEmbedding};
use crate::repo::Repository;
use crate::services::embedding_service::EmbeddingService;
use anyhow::Result;
use surrealdb::types::{RecordId, RecordIdKey, SurrealValue, Value};

impl Repository {
    /// Resolves the visual style for a given relation verb.
    /// Checks local map IRelation records first; if absent, checks IRelation in the global system database.
    pub async fn get_relation_spec(&self, verb: &str) -> Result<Option<RelationStyle>> {
        // 1. Query local map IRelation instances with this verb
        let local_res: Vec<Value> = self
            .db
            .query("SELECT style FROM IRelation WHERE fields.verb = $verb AND fields.style != NONE LIMIT 1")
            .bind(("verb", verb.to_string()))
            .await?
            .take(0)?;

        for val in local_res {
            if let Value::Object(obj) = val {
                if let Some(style_val) = obj.get("style") {
                    if let Ok(style) = RelationStyle::from_value(style_val.clone()) {
                        return Ok(Some(style));
                    }
                }
            }
        }

        // 2. Query global system database (centrode:system)
        if let Ok(sys_db) = centrode_daemon::EngineManager::system_db().await {
            let sys_res: Vec<Value> = sys_db
                .query("SELECT style FROM IRelation WHERE fields.verb = $verb AND fields.style != NONE LIMIT 1")
                .bind(("verb", verb.to_string()))
                .await?
                .take(0)?;

            for val in sys_res {
                if let Value::Object(obj) = val {
                    if let Some(style_val) = obj.get("style") {
                        if let Ok(style) = RelationStyle::from_value(style_val.clone()) {
                            return Ok(Some(style));
                        }
                    }
                }
            }
        }

        Ok(None)
    }

    /// Lists all known relation verbs and styles (combining system defaults and local map customizations).
    pub async fn list_relation_specs(&self) -> Result<Vec<(String, RelationStyle)>> {
        let mut results = std::collections::HashMap::new();

        // 1. Load system defaults from centrode:system IRelation table
        if let Ok(sys_db) = centrode_daemon::EngineManager::system_db().await {
            let sys_res: Vec<Value> = sys_db
                .query("SELECT fields.verb as verb, fields.style as style FROM IRelation WHERE fields.style != NONE")
                .await?
                .take(0)?;

            for val in sys_res {
                if let Value::Object(obj) = val {
                    if let (Some(Value::String(verb)), Some(style_val)) = (obj.get("verb"), obj.get("style")) {
                        if let Ok(style) = RelationStyle::from_value(style_val.clone()) {
                            results.insert(verb.clone(), style);
                        }
                    }
                }
            }
        }

        // 2. Override with local map relation styles
        let local_res: Vec<Value> = self
            .db
            .query("SELECT fields.verb as verb, fields.style as style FROM IRelation WHERE fields.style != NONE")
            .await?
            .take(0)?;

        for val in local_res {
            if let Value::Object(obj) = val {
                if let (Some(Value::String(verb)), Some(style_val)) = (obj.get("verb"), obj.get("style")) {
                    if let Ok(style) = RelationStyle::from_value(style_val.clone()) {
                        results.insert(verb.clone(), style);
                    }
                }
            }
        }

        Ok(results.into_iter().collect())
    }

    /// Adds a word to the custom vocabulary dictionary.
    pub async fn add_custom_word(&self, word: &str, word_type: &str) -> Result<()> {
        let clean = word.trim();
        if clean.is_empty() {
            return Ok(());
        }

        let rid = RecordId::new(
            TableKind::CustomWord.table_name(),
            RecordIdKey::String(clean.to_string()),
        );
        let custom_word = CustomWord {
            key: TypedRecordId::new(TableKind::CustomWord, uuid::Uuid::nil()),
            word: clean.to_string(),
            word_type: word_type.to_string(),
            added_at: chrono::Utc::now().timestamp_millis(),
        };

        let _: Option<CustomWord> = self.db.upsert(rid).content(custom_word).await?;
        Ok(())
    }

    /// Lists all custom vocabulary words.
    pub async fn list_custom_words(&self) -> Result<Vec<CustomWord>> {
        let records: Vec<Value> = self.db.select(TableKind::CustomWord.table_name()).await?;
        let mut words = Vec::new();
        for val in records {
            if let Ok(w) = CustomWord::from_value(val) {
                words.push(w);
            }
        }
        Ok(words)
    }

    /// Removes a word from the custom vocabulary dictionary.
    pub async fn remove_custom_word(&self, word: &str) -> Result<()> {
        let rid = RecordId::new(
            TableKind::CustomWord.table_name(),
            RecordIdKey::String(word.trim().to_string()),
        );
        let _: Option<Value> = self.db.delete(rid).await?;
        Ok(())
    }

    /// Indexes or updates an embedding for a text label.
    pub async fn store_embedding(&self, text_payload: &str) -> Result<()> {
        let clean = text_payload.trim();
        if clean.is_empty() {
            return Ok(());
        }

        let vector = EmbeddingService::embed_text(clean);
        let rid = RecordId::new(
            TableKind::VectorEmbedding.table_name(),
            RecordIdKey::String(clean.to_string()),
        );
        let embedding = VectorEmbedding {
            key: TypedRecordId::new(TableKind::VectorEmbedding, uuid::Uuid::nil()),
            text_payload: clean.to_string(),
            vector,
            created_at: chrono::Utc::now().timestamp_millis(),
        };

        let _: Option<VectorEmbedding> = self.db.upsert(rid).content(embedding).await?;
        Ok(())
    }

    /// Searches for labels semantically similar to the query string (combining ontology, map verbs, and stored embeddings).
    pub async fn search_similar_labels(&self, query: &str, limit: usize) -> Result<Vec<String>> {
        let clean = query.trim();
        if clean.is_empty() {
            return Ok(vec![]);
        }

        let query_vec = EmbeddingService::embed_text(clean);

        // 1. Collect all candidates
        let mut candidates = std::collections::HashSet::new();

        // Built-in ontology verbs
        for &v in &["contradicts", "depends_on", "supports", "causes", "part_of", "leads_to", "blocks"] {
            candidates.insert(v.to_string());
        }

        // Map relations
        if let Ok(mut res) = self.db.query("SELECT fields.verb as verb FROM IRelation").await {
            if let Ok(map_rels) = res.take::<Vec<Value>>(0) {
                for val in map_rels {
                    if let Value::Object(obj) = val {
                        if let Some(Value::String(verb)) = obj.get("verb") {
                            let v = verb.trim();
                            if !v.is_empty() && v != "default" {
                                candidates.insert(v.to_string());
                            }
                        }
                    }
                }
            }
        }

        // Stored vocabulary embeddings
        if let Ok(records) = self.db.select::<Vec<Value>>(TableKind::VectorEmbedding.table_name()).await {
            for val in records {
                if let Ok(emb) = VectorEmbedding::from_value(val) {
                    candidates.insert(emb.text_payload);
                }
            }
        }

        let mut scored: Vec<(String, f32)> = Vec::new();
        for candidate in candidates {
            if candidate.eq_ignore_ascii_case(clean) {
                continue;
            }
            let cand_vec = EmbeddingService::embed_text(&candidate);
            let score = EmbeddingService::cosine_similarity(&query_vec, &cand_vec);
            if score > 0.15 {
                scored.push((candidate, score));
            }
        }

        // Sort descending by cosine similarity
        scored.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap_or(std::cmp::Ordering::Equal));
        scored.truncate(limit);

        Ok(scored.into_iter().map(|(text, _)| text).collect())
    }

    /// Detects the dominant language across the graph's node texts ("en", "fa", "es", "ar", "zh").
    pub fn detect_map_language(node_texts: &[String]) -> String {
        let mut fa_ar_count = 0;
        let mut fa_specific_count = 0;
        let mut zh_count = 0;
        let mut es_count = 0;
        let mut en_count = 0;

        for text in node_texts {
            for ch in text.chars() {
                let cp = ch as u32;
                if (0x0600..=0x06FF).contains(&cp) || (0xFB50..=0xFEFF).contains(&cp) {
                    fa_ar_count += 1;
                    if matches!(ch, 'گ' | 'چ' | 'پ' | 'ژ' | 'ی' | 'ک') {
                        fa_specific_count += 1;
                    }
                } else if (0x4E00..=0x9FFF).contains(&cp) || (0x3400..=0x4DBF).contains(&cp) {
                    zh_count += 1;
                } else if matches!(ch, 'á' | 'é' | 'í' | 'ó' | 'ú' | 'ñ' | '¿' | '¡' | 'Á' | 'É' | 'Í' | 'Ó' | 'Ú' | 'Ñ') {
                    es_count += 2;
                } else if ch.is_ascii_alphabetic() {
                    en_count += 1;
                }
            }
        }

        if fa_ar_count > zh_count && fa_ar_count > es_count && fa_ar_count > en_count {
            if fa_specific_count > 0 {
                "fa".to_string()
            } else {
                "ar".to_string()
            }
        } else if zh_count > fa_ar_count && zh_count > es_count && zh_count > en_count {
            "zh".to_string()
        } else if es_count > 0 && es_count >= (en_count / 3) {
            "es".to_string()
        } else {
            "en".to_string()
        }
    }

    /// Predicts contextual relation predicate labels connecting Source Node and Target Node.
    pub async fn predict_relation_labels(
        &self,
        source_text: &str,
        target_text: &str,
        language: Option<String>,
        limit: usize,
    ) -> Result<Vec<String>> {
        let src = source_text.trim();
        let tgt = target_text.trim();

        if src.is_empty() && tgt.is_empty() {
            return Ok(vec![]);
        }

        let lang = language.as_deref().unwrap_or("en");

        // Canonical relation vocabulary according to target language
        let candidates: &[&str] = match lang {
            "fa" => &[
                "علت", "منجر_به", "وابسته_به", "نیاز_به", "مخالف", "رد_می‌کند",
                "پشتیبانی_می‌کند", "بخشی_از", "متعلق_به", "مانع", "مرتبط_با", "اثرگذار_بر"
            ],
            "es" => &[
                "causa", "produce", "depende_de", "requiere", "contradice", "opone",
                "apoya", "respalda", "parte_de", "pertenece_a", "bloquea", "relacionado_con"
            ],
            "ar" => &[
                "سبب", "يؤدي_إلى", "يعتمد_على", "يتطلب", "يعارض", "يناقض",
                "يدعم", "يساند", "جزء_من", "ينتمي_إلى", "يمنع", "مرتبط_بـ"
            ],
            "zh" => &[
                "导致", "引起", "依赖", "需要", "反对", "矛盾",
                "支持", "部分", "属于", "阻止", "相关", "影响"
            ],
            _ => &[
                "causes", "leads_to", "depends_on", "requires", "contradicts", "opposes",
                "supports", "reinforces", "part_of", "belongs_to", "blocks", "prevents",
                "related_to", "influences"
            ],
        };

        let context_prompt = format!("{} -> {}", src, tgt);
        let context_vec = EmbeddingService::embed_text(&context_prompt);

        let mut scored: Vec<(String, f32)> = Vec::new();
        for &cand in candidates {
            let cand_vec = EmbeddingService::embed_text(cand);
            let score = EmbeddingService::cosine_similarity(&context_vec, &cand_vec);
            scored.push((cand.to_string(), score));
        }

        // Sort descending by semantic similarity to contextual connection
        scored.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap_or(std::cmp::Ordering::Equal));
        scored.truncate(limit);

        Ok(scored.into_iter().map(|(text, _)| text).collect())
    }
}
