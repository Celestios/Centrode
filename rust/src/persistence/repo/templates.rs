use crate::domain::base_models::Record;
use crate::domain::id::TypedRecordId;
use crate::domain::nodes::{IsNode, Nodes};
use crate::domain::relations::IRelation;
use crate::domain::templates::Template;
use crate::domain::theme::{Theme, ThemeFields};
use crate::domain::traits::{SurrealTable, TableKind};
use crate::persistence::repo::Repository;

use anyhow::Result;
use surrealdb::types::{RecordId, RecordIdKey, SurrealValue, Value};

fn key_to_uuid(key: &RecordIdKey) -> uuid::Uuid {
    match key {
        RecordIdKey::Uuid(u) => **u,
        _ => uuid::Uuid::nil(),
    }
}

impl Repository {
    pub async fn get_template(&self, key: String) -> Result<Option<Template>> {
        let record_id = if let Ok(u) = uuid::Uuid::parse_str(&key) {
            TypedRecordId::new(TableKind::Template, u).to_record_id()
        } else {
            RecordId::new(Template::LABEL, key)
        };
        let val: Option<Value> = self.db.select(record_id).await?;
        match val {
            Some(v) => {
                let record = Record::from_record_value(v)
                    .ok_or_else(|| anyhow::anyhow!("Failed to parse Template record"))?;
                let mut template = Template::from_value(record.fields)?;
                template.key = TypedRecordId::new(TableKind::Template, key_to_uuid(&record.id.key));
                Ok(Some(template))
            }
            None => Ok(None),
        }
    }

    pub async fn save_template(
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

    pub async fn list_templates(&self) -> Result<Vec<Template>> {
        let vals: Vec<Value> = self.db.select(Template::LABEL).await?;
        let mut result = Vec::new();
        for v in vals {
            if let Some(record) = Record::from_record_value(v) {
                if let Ok(mut template) = Template::from_value(record.fields) {
                    template.key = TypedRecordId::new(TableKind::Template, key_to_uuid(&record.id.key));
                    result.push(template);
                }
            }
        }
        Ok(result)
    }

    pub async fn delete_template(&self, key: String) -> Result<()> {
        let record_id = if let Ok(u) = uuid::Uuid::parse_str(&key) {
            TypedRecordId::new(TableKind::Template, u).to_record_id()
        } else {
            RecordId::new(Template::LABEL, key)
        };
        self.db.delete::<Option<Value>>(record_id).await?;
        Ok(())
    }

    pub async fn apply_template(
        &self,
        key: String,
        target_x: f64,
        target_y: f64,
    ) -> Result<()> {
        let record_id = if let Ok(u) = uuid::Uuid::parse_str(&key) {
            TypedRecordId::new(TableKind::Template, u).to_record_id()
        } else {
            RecordId::new(Template::LABEL, key.clone())
        };
        let template_val: Option<Value> = self.db.select(record_id).await?;
        let template_val = template_val.ok_or_else(|| anyhow::anyhow!("Template not found"))?;
        let record = Record::from_record_value(template_val)
            .ok_or_else(|| anyhow::anyhow!("Failed to parse Template record"))?;
        let template = Template::from_value(record.fields)?;

        use std::collections::HashMap;
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

        for node in new_nodes {
            self.create_node(node).await?;
        }
        for rel in new_relations {
            self.create_relation(rel.clone()).await?;
        }

        Ok(())
    }

    pub async fn get_theme(&self, key: String) -> Result<Option<Theme>> {
        let record_id = RecordId::new(Theme::LABEL, key.clone());
        let val: Option<Value> = self.db.select(record_id).await?;
        match val {
            Some(v) => {
                let fields = ThemeFields::from_value(v)?;
                let u = uuid::Uuid::parse_str(&key).unwrap_or_else(|_| uuid::Uuid::nil());
                let typed_id = TypedRecordId::new(TableKind::MapTheme, u);
                Ok(Some(Theme { key: typed_id, fields }))
            }
            None => Ok(None),
        }
    }

    pub async fn get_theme_by_key(&self, key: &str) -> Result<Option<Theme>> {
        let u = uuid::Uuid::parse_str(key).unwrap_or_else(|_| uuid::Uuid::nil());
        let typed_id = TypedRecordId::new(TableKind::MapTheme, u);
        let val: Option<Value> = self.db.select(typed_id.to_record_id()).await?;
        let fields = val.map(|v| ThemeFields::from_value(v)).transpose()?;
        Ok(fields.map(|f| Theme { key: typed_id, fields: f }))
    }

    pub async fn save_theme(&self, theme: Theme) -> Result<Theme> {
        let record_id = theme.key.to_record_id();
        let _: Option<Value> = self.db
            .create(record_id)
            .content(theme.fields.clone().into_value())
            .await?;
        Ok(theme)
    }

    pub async fn list_themes(&self) -> Result<Vec<Theme>> {
        let vals: Vec<Value> = self.db.select(Theme::LABEL).await?;
        let mut result = Vec::new();
        for v in vals {
            if let Some(record) = Record::from_record_value(v) {
                if let Ok(fields) = ThemeFields::from_value(record.fields) {
                    let key = TypedRecordId::new(TableKind::MapTheme, key_to_uuid(&record.id.key));
                    result.push(Theme { key, fields });
                }
            }
        }
        Ok(result)
    }
}
