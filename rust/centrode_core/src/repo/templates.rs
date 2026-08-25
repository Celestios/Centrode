use std::collections::HashMap;
use crate::domain::base_models::Record;
use crate::domain::id::TypedRecordId;
use crate::domain::nodes::{IsNode, Nodes};
use crate::domain::relations::IRelation;
use crate::domain::templates::Template;
use crate::domain::traits::TableKind;
use crate::repo::nodes::SurrealNodeRepository;
use crate::repo::relations::SurrealRelationRepository;
use crate::repo::traits::{NodeRepository, RelationRepository, TemplateRepository};

use anyhow::Result;
use surrealdb::engine::local::Db;
use surrealdb::types::{RecordIdKey, SurrealValue, Value};
use surrealdb::Surreal;

fn key_to_uuid(key: &RecordIdKey) -> Result<uuid::Uuid> {
    match key {
        RecordIdKey::Uuid(u) => Ok(**u),
        _ => Err(anyhow::anyhow!("Non-UUID template key")),
    }
}

#[derive(Clone)]
pub struct SurrealTemplateRepository {
    pub(crate) db: Surreal<Db>,
}

impl SurrealTemplateRepository {
    pub fn new(db: Surreal<Db>) -> Self {
        Self { db }
    }

    pub fn db(&self) -> &Surreal<Db> {
        &self.db
    }
}

impl TemplateRepository for SurrealTemplateRepository {
    async fn get_template(&self, key: String) -> Result<Option<Template>> {
        let u = uuid::Uuid::parse_str(&key)
            .map_err(|e| anyhow::anyhow!("Invalid template key '{}': {}", key, e))?;
        let record_id = TypedRecordId::new(TableKind::Template, u).to_record_id();
        let val: Option<Value> = self.db.select(record_id).await?;
        match val {
            Some(v) => {
                let record = Record::from_record_value(v)
                    .ok_or_else(|| anyhow::anyhow!("Failed to parse Template record"))?;
                let mut template = Template::from_value(record.fields)?;
                template.key = TypedRecordId::new(TableKind::Template, key_to_uuid(&record.id.key)?);
                Ok(Some(template))
            }
            None => Ok(None),
        }
    }

    async fn save_template(
        &self,
        name: String,
        nodes: Vec<Nodes>,
        relations: Vec<IRelation>,
    ) -> Result<Template> {
        let template = Template::from_selection(name, nodes, relations)?;
        let record_id = template.key.to_record_id();
        let mut val = template.clone().into_value();
        if let Value::Object(ref mut map) = val {
            map.remove("id");
        }
        let _: Option<Value> = self.db
            .create(record_id)
            .content(val)
            .await?;
        Ok(template)
    }

    async fn list_templates(&self) -> Result<Vec<Template>> {
        let vals: Vec<Value> = self.db.select(Template::LABEL).await?;
        let mut result = Vec::new();
        for v in vals {
            if let Some(record) = Record::from_record_value(v) {
                if let Ok(mut template) = Template::from_value(record.fields) {
                    template.key = TypedRecordId::new(TableKind::Template, key_to_uuid(&record.id.key)?);
                    result.push(template);
                }
            }
        }
        Ok(result)
    }

    async fn delete_template(&self, key: String) -> Result<()> {
        let u = uuid::Uuid::parse_str(&key)
            .map_err(|e| anyhow::anyhow!("Invalid template key '{}': {}", key, e))?;
        let record_id = TypedRecordId::new(TableKind::Template, u).to_record_id();
        self.db.delete::<Option<Value>>(record_id).await?;
        Ok(())
    }

    async fn apply_template(
        &self,
        key: String,
        target_x: f64,
        target_y: f64,
    ) -> Result<(Vec<Nodes>, Vec<IRelation>)> {
        let u = uuid::Uuid::parse_str(&key)
            .map_err(|e| anyhow::anyhow!("Invalid template key '{}': {}", key, e))?;
        let record_id = TypedRecordId::new(TableKind::Template, u).to_record_id();
        let template_val: Option<Value> = self.db.select(record_id).await?;
        let template_val = template_val.ok_or_else(|| anyhow::anyhow!("Template not found"))?;
        let record = Record::from_record_value(template_val)
            .ok_or_else(|| anyhow::anyhow!("Failed to parse Template record"))?;
        let template = Template::from_value(record.fields)?;

        let mut key_map = HashMap::new();
        for node in &template.nodes {
            let old_key = node.id().to_string();
            let new_id = TypedRecordId::new_v4(node.id().table);
            key_map.insert(old_key, new_id);
        }

        let target_xi = target_x.round() as i32;
        let target_yi = target_y.round() as i32;

        let mut new_nodes = Vec::new();
        for node in &template.nodes {
            let mut cloned_node = node.clone();
            let old_key = cloned_node.id().to_string();
            if let Some(new_id) = key_map.get(&old_key) {
                cloned_node.set_id(*new_id);
            }

            let pos = cloned_node.position_mut();
            pos.x += target_xi;
            pos.y += target_yi;

            let now = chrono::Utc::now().timestamp_millis();
            cloned_node.set_created_at(now);
            cloned_node.set_updated_at(now);

            new_nodes.push(cloned_node);
        }

        let mut new_relations = Vec::new();
        for rel in &template.relations {
            let mut cloned_rel = rel.clone();
            cloned_rel.key = TypedRecordId::new_v4(TableKind::IRelation);

            if let Some(new_in) = key_map.get(&cloned_rel.in_.to_string()) {
                cloned_rel.in_ = *new_in;
            }
            if let Some(new_out) = key_map.get(&cloned_rel.out.to_string()) {
                cloned_rel.out = *new_out;
            }

            let now = chrono::Utc::now().timestamp_millis();
            cloned_rel.fields.created_at = now;
            cloned_rel.fields.updated_at = now;

            new_relations.push(cloned_rel);
        }

        let result_nodes = new_nodes.clone();
        let result_relations = new_relations.clone();

        let node_repo = SurrealNodeRepository::new(self.db.clone());
        let rel_repo = SurrealRelationRepository::new(self.db.clone());

        for node in new_nodes {
            node_repo.create_node(node).await?;
        }
        for rel in new_relations {
            rel_repo.create_relation(rel).await?;
        }

        Ok((result_nodes, result_relations))
    }
}
