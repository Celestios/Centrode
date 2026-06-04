use crate::domain::base_models::{IsTable, MapData, Record, RecordStrings, ViewportState};
use crate::domain::nodes::IsNode;
use crate::domain::relations::IRelation;
use crate::domain::templates::Template;
use crate::domain::theme::{Theme, ThemeFields};
use crate::persistence::repo::Repository;

use anyhow::Result;
use surrealdb::types::{RecordId, SurrealValue, Value};

impl Repository {
    pub async fn create_template(&self, template: Template) -> Result<()> {
        let record_id = RecordId::new(Template::LABEL, template.key.clone());
        let _: Option<Template> = self.db.create(record_id).content(template).await?;
        Ok(())
    }

    pub async fn get_all_templates(&self) -> Result<Vec<Template>> {
        let records: Vec<Value> = self.db.select(Template::LABEL).await?;
        let mut templates = Vec::new();
        for val in records {
            if let Some(record) = Record::from_record_value(val.clone()) {
                match Template::from_value(record.fields) {
                    Ok(tpl) => templates.push(tpl),
                    Err(e) => {
                        tracing::error!("Template deserialization failed: {:?}", e);
                    }
                }
            } else {
                tracing::error!("Record::from_record_value failed for template: {:?}", val);
            }
        }
        Ok(templates)
    }

    pub async fn delete_template(&self, key: String) -> Result<()> {
        let record_id = RecordId::new(Template::LABEL, key);
        let _: Option<Value> = self.db.delete(record_id).await?;
        Ok(())
    }

    pub async fn save_template_from_selection(
        &self,
        name: String,
        node_keys: Vec<RecordStrings>,
        relation_keys: Vec<RecordStrings>,
    ) -> Result<()> {
        let mut nodes = Vec::new();
        for rstr in &node_keys {
            if let Some(node) = self.get_node(rstr.table.clone(), rstr.key.clone()).await? {
                nodes.push(node);
            }
        }

        let mut relations = Vec::new();
        for rstr in &relation_keys {
            let rel = self
                .get_relation(rstr.table.clone(), rstr.key.clone())
                .await?;
            relations.push(rel);
        }

        let template = Template::from_selection(name, nodes, relations)?;

        self.create_template(template).await?;
        Ok(())
    }

    pub async fn instantiate_template(
        &self,
        key: String,
        target_x: f64,
        target_y: f64,
    ) -> Result<()> {
        let record_id = RecordId::new(Template::LABEL, key.clone());
        let template_val: Option<Value> = self.db.select(record_id).await?;
        let template_val = template_val.ok_or_else(|| anyhow::anyhow!("Template not found"))?;
        let record = Record::from_record_value(template_val)
            .ok_or_else(|| anyhow::anyhow!("Failed to parse Template record"))?;
        let template = Template::from_value(record.fields)?;

        use std::collections::HashMap;
        let mut key_map = HashMap::new();
        for node in &template.nodes {
            let old_key = node.key().to_string();
            let new_key = uuid::Uuid::new_v4().to_string();
            key_map.insert(old_key, new_key);
        }

        let target_xi = target_x.round() as i32;
        let target_yi = target_y.round() as i32;

        let mut new_nodes = Vec::new();
        for node in &template.nodes {
            let mut cloned_node = node.clone();
            let old_key = cloned_node.key().to_string();
            let new_key = key_map.get(&old_key).unwrap().clone();

            cloned_node.set_key(new_key);

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
            cloned_rel.key = uuid::Uuid::new_v4().to_string();

            if let Some(new_in_key) = key_map.get(&cloned_rel.in_.key) {
                cloned_rel.in_.key = new_in_key.clone();
            }
            if let Some(new_out_key) = key_map.get(&cloned_rel.out.key) {
                cloned_rel.out.key = new_out_key.clone();
            }

            let now = chrono::Utc::now().timestamp_millis();
            cloned_rel.fields.created_at = now;
            cloned_rel.fields.updated_at = now;

            new_relations.push(cloned_rel);
        }

        let db = self.db.clone();
        let tx = db.begin().await?;

        for node in new_nodes {
            let (table, key) = {
                let (t, k) = node.table_and_key();
                (t, k.to_string())
            };
            let document = node.serialize_node();
            let _: Option<Value> = tx.create((table, key)).content(document).await?;
        }

        for relation in new_relations {
            let in_id = relation.in_.clone();
            let out_id = relation.out.clone();
            let record = RecordId::new(IRelation::LABEL, relation.key.clone());

            let mut res = tx
                .query("RELATE $from -> $record -> $out CONTENT $data")
                .bind(("record", record))
                .bind(("from", in_id.into_record()))
                .bind(("out", out_id.into_record()))
                .bind(("data", relation))
                .await?;
            let _: Option<Value> = res.take(0)?;
        }

        tx.commit().await?;
        Ok(())
    }

    pub async fn get_all_themes(&self) -> Result<Vec<Theme>> {
        tracing::debug!("REPO: get_all_themes called");
        let theme_records: Vec<Value> = self.db.select(Theme::LABEL).await?;
        let themes: Vec<Theme> = theme_records
            .into_iter()
            .filter_map(|val| {
                let record = Record::from_record_value(val)?;
                let (key, fields) = record.to_type::<ThemeFields>()?;
                Some(Theme { key, fields })
            })
            .collect();
        Ok(themes)
    }

    pub async fn get_theme(&self, key: String) -> Result<Option<Theme>> {
        tracing::debug!("REPO: get_theme called with key: {}", key);
        let record_id = RecordId::new(Theme::LABEL, key.clone());
        let fields: Option<ThemeFields> = self.db.select(record_id).await?;
        Ok(fields.map(|f| Theme { key, fields: f }))
    }

    pub async fn set_active_theme_id(&self, theme_id: String) -> Result<()> {
        tracing::debug!("REPO: set_active_theme_id called with id: {}", theme_id);
        let record_id = RecordId::new(MapData::LABEL, MapData::KEY);
        self.db
            .query("UPDATE $record SET active_theme_id = $theme_id")
            .bind(("record", record_id))
            .bind(("theme_id", theme_id))
            .await?;
        Ok(())
    }

    pub async fn update_viewport_state(&self, state: ViewportState) -> Result<()> {
        tracing::debug!("REPO: update_viewport_state called with state: {:?}", state);
        let record_id = RecordId::new(MapData::LABEL, MapData::KEY);
        self.db
            .query("UPDATE $record SET viewport_state = $state")
            .bind(("record", record_id))
            .bind(("state", state))
            .await?;
        Ok(())
    }

    pub async fn get_active_theme_id(&self) -> Result<Option<String>> {
        tracing::debug!("REPO: get_active_theme_id called");
        let mut res = self
            .db
            .query("SELECT VALUE active_theme_id FROM $record")
            .bind(("record", RecordId::new(MapData::LABEL, MapData::KEY)))
            .await?;
        let result: Option<String> = res.take(0)?;
        Ok(result)
    }

    pub async fn set_active_theme(&self, theme_key: String) -> Result<()> {
        tracing::debug!("REPO: set_active_theme called with key: {}", theme_key);
        let _: Option<Theme> = self.db.update((MapData::LABEL, theme_key)).await?;
        Ok(())
    }

    pub async fn create_theme(&self, key: String, fields: ThemeFields) -> Result<()> {
        tracing::debug!("REPO: create_theme called");
        let record_id = RecordId::new(Theme::LABEL, key);
        self.db
            .query("CREATE $record_id CONTENT $fields")
            .bind(("record_id", record_id))
            .bind(("fields", fields))
            .await?;
        Ok(())
    }

    pub async fn update_theme(&self, theme: Theme) -> Result<()> {
        tracing::debug!("REPO: update_theme called");
        let record_id = RecordId::new(Theme::LABEL, theme.key);
        let fields = theme.fields;
        self.db
            .query("UPDATE $record_id MERGE $fields")
            .bind(("record_id", record_id))
            .bind(("fields", fields))
            .await?;
        Ok(())
    }
}
