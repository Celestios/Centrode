use std::cmp::Ordering;
use std::collections::{HashMap, HashSet};
use std::sync::OnceLock;

use crate::domain::id::TypedRecordId;
use crate::domain::styles::RelationStyle;
use crate::domain::traits::TableKind;
use crate::domain::types::{CustomWord, VectorEmbedding};
use crate::repo::traits::DictionaryRepository;
use crate::services::embedding_service::EmbeddingService;

use anyhow::Result;
use centrode_daemon::EngineManager;
use surrealdb::engine::local::Db;
use surrealdb::types::{RecordId, RecordIdKey, SurrealValue, Value};
use surrealdb::Surreal;

#[derive(Debug, Clone)]
pub struct OntologyIndex {
    pub by_lang_and_cat: HashMap<(String, String), Vec<String>>,
}

pub fn get_official_ontology_index() -> &'static OntologyIndex {
    static INDEX: OnceLock<OntologyIndex> = OnceLock::new();
    INDEX.get_or_init(|| {
        let mut map: HashMap<(String, String), Vec<String>> = HashMap::new();
        if let Some((en_labels, fa_labels)) = crate::services::knowledge_graph_engine::KnowledgeGraphEngine::with_global(|engine| {
            let mut en = Vec::with_capacity(engine.ontology.len() * 2);
            let mut fa = Vec::with_capacity(engine.ontology.len());
            for entry in &engine.ontology {
                en.push(entry.en_label.clone());
                en.push(entry.name.clone());
                fa.push(entry.fa_label.clone());
            }
            (en, fa)
        }) {
            map.insert(("en".to_string(), "relation".to_string()), en_labels);
            map.insert(("fa".to_string(), "relation".to_string()), fa_labels);
        }
        OntologyIndex { by_lang_and_cat: map }
    })
}

pub fn damerau_levenshtein(s1: &str, s2: &str) -> usize {
    let v1: Vec<char> = s1.chars().collect();
    let v2: Vec<char> = s2.chars().collect();
    let len1 = v1.len();
    let len2 = v2.len();

    if len1 == 0 {
        return len2;
    }
    if len2 == 0 {
        return len1;
    }

    let mut d = vec![vec![0usize; len2 + 1]; len1 + 1];

    for i in 0..=len1 {
        d[i][0] = i;
    }
    for j in 0..=len2 {
        d[0][j] = j;
    }

    for i in 1..=len1 {
        for j in 1..=len2 {
            let cost = if v1[i - 1].eq_ignore_ascii_case(&v2[j - 1]) { 0 } else { 1 };
            d[i][j] = (d[i - 1][j] + 1)
                .min(d[i][j - 1] + 1)
                .min(d[i - 1][j - 1] + cost);

            if i > 1 && j > 1 && v1[i - 1].eq_ignore_ascii_case(&v2[j - 2]) && v1[i - 2].eq_ignore_ascii_case(&v2[j - 1]) {
                d[i][j] = d[i][j].min(d[i - 2][j - 2] + 1);
            }
        }
    }

    d[len1][len2]
}

#[derive(Clone)]
pub struct SurrealDictionaryRepository {
    pub(crate) db: Surreal<Db>,
}

impl SurrealDictionaryRepository {
    pub fn new(db: Surreal<Db>) -> Self {
        Self { db }
    }

    pub fn db(&self) -> &Surreal<Db> {
        &self.db
    }

    pub fn detect_map_language(node_texts: &[String]) -> String {
        Self::detect_map_language_impl(node_texts)
    }

    fn detect_map_language_impl(node_texts: &[String]) -> String {
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
}

impl DictionaryRepository for SurrealDictionaryRepository {
    async fn get_relation_spec(&self, verb: &str) -> Result<Option<RelationStyle>> {
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
        if let Ok(sys_db) = EngineManager::system_db().await {
            let sys_res: Vec<Value> = sys_db
                .query("SELECT style FROM IRelation WHERE (verb = $verb OR verb.name = $verb OR verb.en_label = $verb OR verb.fa_label = $verb OR verb.label = $verb OR fields.verb = $verb) AND (style != NONE OR fields.style != NONE) LIMIT 1")
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

    async fn list_relation_specs(&self) -> Result<Vec<(String, RelationStyle)>> {
        let mut results = HashMap::new();

        // 1. Load system defaults from centrode:system IRelation table
        if let Ok(sys_db) = EngineManager::system_db().await {
            let sys_res: Vec<Value> = sys_db
                .query("SELECT verb, style, fields.verb as f_verb, fields.style as f_style FROM IRelation WHERE style != NONE OR fields.style != NONE")
                .await?
                .take(0)?;

            for val in sys_res {
                if let Value::Object(obj) = val {
                    let verb_str = match obj.get("verb").or_else(|| obj.get("f_verb")) {
                        Some(Value::String(s)) => Some(s.clone()),
                        Some(Value::Object(v_obj)) => {
                            if let Some(Value::String(lbl)) = v_obj.get("en_label") {
                                Some(lbl.clone())
                            } else if let Some(Value::String(name)) = v_obj.get("name") {
                                Some(name.clone())
                            } else {
                                None
                            }
                        }
                        _ => None,
                    };
                    let style_val = obj.get("style").or_else(|| obj.get("f_style"));
                    if let (Some(verb), Some(s_val)) = (verb_str, style_val) {
                        if let Ok(style) = RelationStyle::from_value(s_val.clone()) {
                            results.insert(verb, style);
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

    async fn add_custom_word(&self, word: &str, word_type: &str) -> Result<()> {
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

    async fn list_custom_words(&self) -> Result<Vec<CustomWord>> {
        let records: Vec<Value> = self.db.select(TableKind::CustomWord.table_name()).await?;
        let mut words = Vec::new();
        for val in records {
            if let Ok(w) = CustomWord::from_value(val) {
                words.push(w);
            }
        }
        Ok(words)
    }

    async fn remove_custom_word(&self, word: &str) -> Result<()> {
        let rid = RecordId::new(
            TableKind::CustomWord.table_name(),
            RecordIdKey::String(word.trim().to_string()),
        );
        let _: Option<Value> = self.db.delete(rid).await?;
        Ok(())
    }

    async fn store_embedding(&self, text_payload: &str) -> Result<()> {
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

    async fn search_similar_labels(
        &self,
        query: &str,
        category: Option<String>,
        language: Option<String>,
        limit: usize,
    ) -> Result<Vec<String>> {
        let clean = query.trim();
        if clean.is_empty() {
            return Ok(vec![]);
        }

        let query_vec = EmbeddingService::embed_text(clean);
        let mut candidates = HashSet::new();

        let lang = language.as_deref().unwrap_or("en");
        let target_category = category.as_deref().unwrap_or("relation");

        // 1. Canonical Knowledge Graph Ontology from centrode:system IRelation
        if target_category == "relation" {
            if let Ok(sys_db) = EngineManager::system_db().await {
                if let Ok(mut res) = sys_db.query("SELECT verb FROM IRelation WHERE verb != NONE").await {
                    if let Ok(sys_rels) = res.take::<Vec<Value>>(0) {
                        for val in sys_rels {
                            if let Value::Object(obj) = val {
                                if let Some(Value::Object(v_obj)) = obj.get("verb") {
                                    match lang {
                                        "fa" => {
                                            if let Some(Value::String(fa)) = v_obj.get("fa_label") {
                                                candidates.insert(fa.clone());
                                            }
                                        }
                                        _ => {
                                            if let Some(Value::String(en)) = v_obj.get("en_label") {
                                                candidates.insert(en.clone());
                                            }
                                            if let Some(Value::String(name)) = v_obj.get("name") {
                                                candidates.insert(name.clone());
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // 1b. Knowledge Graph Ontology & Spelling Lexicon (in-memory index lookup)
        let index = get_official_ontology_index();
        if let Some(words) = index.by_lang_and_cat.get(&(lang.to_string(), target_category.to_string())) {
            for word in words {
                candidates.insert(word.clone());
            }
        }

        // 2. Dynamic map relations (if category is relation)
        if target_category == "relation" {
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
        }

        // 3. Stored vocabulary embeddings
        if let Ok(records) = self.db.select::<Vec<Value>>(TableKind::VectorEmbedding.table_name()).await {
            for val in records {
                if let Ok(emb) = VectorEmbedding::from_value(val) {
                    candidates.insert(emb.text_payload);
                }
            }
        }

        let query_norm = clean.replace('_', " ").replace('-', " ");
        let query_lower = query_norm.to_lowercase();

        let mut scored: Vec<(String, f32)> = Vec::new();
        for candidate in candidates {
            if candidate.eq_ignore_ascii_case(clean) {
                continue;
            }
            let cand_norm = candidate.replace('_', " ").replace('-', " ");
            let cand_lower = cand_norm.to_lowercase();

            // 1. Semantic Embedding Similarity (BERT unit vector dot product)
            let cand_vec = EmbeddingService::embed_text(&candidate);
            let neural_sim = EmbeddingService::cosine_similarity(&query_vec, &cand_vec);

            // 2. Fuzzy Typo & Edit Distance Similarity
            let edit_dist = damerau_levenshtein(&query_lower, &cand_lower);
            let max_len = query_lower.chars().count().max(cand_lower.chars().count());
            let edit_sim = if max_len > 0 {
                1.0 - (edit_dist as f32 / max_len as f32)
            } else {
                0.0
            };

            // 3. Prefix, Substring, and Typo Boost
            let prefix_bonus = if cand_lower.starts_with(&query_lower) {
                0.35
            } else if cand_lower.contains(&query_lower) {
                0.20
            } else if edit_dist <= 2 {
                0.30 // strong boost for 1-2 character typos (e.g. "becuse" -> "because", "cuases" -> "causes")
            } else {
                0.0
            };

            let hybrid_score = (0.5 * neural_sim + 0.5 * edit_sim + prefix_bonus).min(1.0);

            if hybrid_score > 0.20 || edit_dist <= 2 {
                scored.push((candidate, hybrid_score));
            }
        }

        // Sort descending by hybrid similarity score
        scored.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap_or(Ordering::Equal));
        scored.truncate(limit);

        Ok(scored.into_iter().map(|(text, _)| text).collect())
    }

    fn detect_map_language(&self, node_texts: &[String]) -> String {
        Self::detect_map_language_impl(node_texts)
    }

    async fn predict_relation_labels(
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

        // 1. Primary: Query canonical relation verb objects from centrode:system SurrealDB
        if let Ok(sys_db) = EngineManager::system_db().await {
            let sys_res: Vec<Value> = sys_db
                .query("SELECT verb FROM IRelation WHERE verb != NONE")
                .await?
                .take(0)?;

            if !sys_res.is_empty() {
                let context_prompt = format!("{} {}", src, tgt);
                let context_vec = EmbeddingService::embed_text(&context_prompt);

                let mut candidates: Vec<(String, f32)> = Vec::with_capacity(sys_res.len());
                for val in sys_res {
                    if let Value::Object(obj) = val {
                        if let Some(Value::Object(verb_obj)) = obj.get("verb") {
                            let en_template = match verb_obj.get("en_template") {
                                Some(Value::String(s)) => s.as_str(),
                                _ => "{head} {tail}",
                            };
                            let fa_template = match verb_obj.get("fa_template") {
                                Some(Value::String(s)) => s.as_str(),
                                _ => en_template,
                            };
                            let en_label = match verb_obj.get("en_label") {
                                Some(Value::String(s)) => s.clone(),
                                _ => match verb_obj.get("name") {
                                    Some(Value::String(s)) => s.clone(),
                                    _ => String::new(),
                                },
                            };
                            let fa_label = match verb_obj.get("fa_label") {
                                Some(Value::String(s)) => s.clone(),
                                _ => en_label.clone(),
                            };

                            let templated = match lang {
                                "fa" => fa_template.replace("{head}", src).replace("{tail}", tgt),
                                _ => en_template.replace("{head}", src).replace("{tail}", tgt),
                            };
                            let cand_vec = EmbeddingService::embed_text(&templated);
                            let score = EmbeddingService::cosine_similarity(&context_vec, &cand_vec);
                            let label = match lang {
                                "fa" => fa_label,
                                _ => en_label,
                            };
                            if !label.is_empty() {
                                candidates.push((label, score));
                            }
                        }
                    }
                }

                if !candidates.is_empty() {
                    candidates.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap_or(Ordering::Equal));
                    candidates.truncate(limit);
                    return Ok(candidates.into_iter().map(|(lbl, _)| lbl).collect());
                }
            }
        }

        // Fallback: in-memory KnowledgeGraphEngine if available
        if let Some(scored_candidates) = crate::services::knowledge_graph_engine::KnowledgeGraphEngine::with_global(|engine| {
            if engine.ontology.is_empty() {
                return vec![];
            }

            let context_prompt = format!("{} {}", src, tgt);
            let context_vec = EmbeddingService::embed_text(&context_prompt);

            let mut candidates: Vec<(String, f32)> = Vec::with_capacity(engine.ontology.len());
            for entry in &engine.ontology {
                let templated = match lang {
                    "fa" => entry.fa_template.replace("{head}", src).replace("{tail}", tgt),
                    _ => entry.en_template.replace("{head}", src).replace("{tail}", tgt),
                };
                let cand_vec = EmbeddingService::embed_text(&templated);
                let score = EmbeddingService::cosine_similarity(&context_vec, &cand_vec);
                let label = match lang {
                    "fa" => entry.fa_label.clone(),
                    _ => entry.en_label.clone(),
                };
                candidates.push((label, score));
            }

            candidates.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap_or(Ordering::Equal));
            candidates.truncate(limit);
            candidates.into_iter().map(|(lbl, _)| lbl).collect()
        }) {
            if !scored_candidates.is_empty() {
                return Ok(scored_candidates);
            }
        }

        let index = get_official_ontology_index();
        let empty_list = Vec::new();
        let candidates = index.by_lang_and_cat.get(&(lang.to_string(), "relation".to_string())).unwrap_or(&empty_list);

        if candidates.is_empty() {
            return Ok(vec![]);
        }

        let context_prompt = format!("{} {}", src, tgt);
        let context_vec = EmbeddingService::embed_text(&context_prompt);

        let mut scored: Vec<(String, f32)> = Vec::new();
        for cand in candidates {
            let cand_vec = EmbeddingService::embed_text(cand);
            let score = EmbeddingService::cosine_similarity(&context_vec, &cand_vec);
            scored.push((cand.to_string(), score));
        }

        scored.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap_or(Ordering::Equal));
        scored.truncate(limit);

        Ok(scored.into_iter().map(|(text, _)| text).collect())
    }
}
