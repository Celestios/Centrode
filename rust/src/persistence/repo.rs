use crate::domain::base_models::{BoundingBox, IsTable, MapData, Record, RecordStrings, ViewportState};
use crate::domain::nodes::{INode, InterNode, IsNode, Nodes, TaskNode};
use crate::domain::patches::{
    EntityPatch, NodePatch, PatchHistoryPayload, RelationPatch, TagOperation,
};
use crate::domain::relations::{IRelation, IRelationFields};
use crate::domain::snapshot::GraphSnapshot;
use crate::domain::tags::{Tag, TagFields};
use crate::domain::templates::Template;
use crate::domain::theme::{Theme, ThemeFields};
use crate::persistence::history::{HistoryManager, HistoryRecord};

use anyhow::Result;
use surrealdb::engine::local::Db;
use surrealdb::types::{RecordId, SurrealValue, Value};
use surrealdb::Surreal;
use tracing::{debug, info};

#[derive(Clone)]
pub struct Repository {
    db: Surreal<Db>,
}

impl Repository {
    pub fn new(db: Surreal<Db>) -> Self {
        Self { db }
    }

    pub fn db(&self) -> &Surreal<Db> {
        &self.db
    }

    pub async fn create_node<N>(&self, input: N) -> Result<()>
    where
        N: IsNode,
    {
        let table = input.table_name();
        let key = input.key().to_string();
        let val = input.serialize_node();
        let _: Option<Value> = self
            .db
            .create((table, key.clone()))
            .content(val)
            .await?;
        info!("REPO: Created Node of table {} with ID: {}", table, key);
        Ok(())
    }

    pub async fn create_relation(&self, input: IRelation) -> Result<()> {
        let key = input.key.clone();
        let in_id = input.in_.clone();
        let out_id = input.out.clone();
        let record = RecordId::new(IRelation::LABEL, key.clone());

        let mut res = self
            .db
            .query("RELATE $from -> $record -> $out CONTENT $data")
            .bind(("record", record))
            .bind(("from", in_id.into_record()))
            .bind(("out", out_id.into_record()))
            .bind(("data", input))
            .await?;
        let created: Option<Value> = res.take(0)?;
        let _ = created.ok_or_else(|| anyhow::anyhow!("Failed to create Relation"))?;

        self.trigger_significance_update(&in_id).await?;
        self.trigger_significance_update(&out_id).await?;

        info!("REPO: Created Relation with ID: {}", key);
        info!("REPO: Created Relation from {:?} to {:?}", in_id, out_id);

        Ok(())
    }

    pub async fn trigger_significance_update(&self, node_id: &RecordStrings) -> Result<()> {
        let self_clone = self.clone();
        let id_clone = node_id.clone();

        tokio::spawn(async move {
            if let Err(e) = self_clone.recalculate_significance_area(id_clone).await {
                tracing::error!("Significance update failed: {}", e);
            }
            // TODO: Broadcast SignificanceUpdate packet via FFI Sink
        });

        Ok(())
    }

    pub async fn recalculate_significance_area(&self, center_node_id: RecordStrings) -> Result<()> {
        tracing::info!(
            "ANALYSIS: Recalculating significance area for center node: {:?}",
            center_node_id.to_str()
        );

        let sql = format!(
            "
            LET $targets = (SELECT VALUE `out` FROM {0} WHERE `in` = $center);
            
            FOR $node_id IN $targets {{
                LET $neighbors = (SELECT VALUE `out` FROM {0} WHERE `in` = $node_id);
                LET $d1 = array::len($neighbors);
                LET $d2 = array::len(SELECT VALUE id FROM {0} WHERE $neighbors CONTAINS `in`);
                
                LET $raw_score = ($d1 * 1.0) + ($d2 * 0.5);
                
                LET $level = math::min([4, math::floor($raw_score / 2.0)]);
                
                UPDATE $node_id SET significance = $level;
            }};
            ",
            IRelation::LABEL,
        );

        self.db.query(sql)
            .bind(("center", center_node_id.into_record()))
            .await?;

        tracing::info!(
            "ANALYSIS: Significance area recalculated successfully for {:?}",
            center_node_id
        );
        Ok(())
    }

    pub async fn calculate_global_bounds(&self) -> Result<BoundingBox> {
        let sql = format!(
            "
            LET $xs = (SELECT VALUE position.x FROM {0}, {1}, {2} WHERE position.x != NONE);
            LET $ys = (SELECT VALUE position.y FROM {0}, {1}, {2} WHERE position.y != NONE);
            RETURN {{
                min_x: <float> math::min($xs),
                max_x: <float> math::max($xs),
                min_y: <float> math::min($ys),
                max_y: <float> math::max($ys)
            }};
            ",
            INode::LABEL,
            TaskNode::LABEL,
            InterNode::LABEL,
        );

        let mut res = self.db.query(sql).await?;
        let min_x: Option<f64> = res.take((2, "min_x"))?;
        let max_x: Option<f64> = res.take((2, "max_x"))?;
        let min_y: Option<f64> = res.take((2, "min_y"))?;
        let max_y: Option<f64> = res.take((2, "max_y"))?;

        if let (Some(mx), Some(mxx), Some(my), Some(mxy)) = (min_x, max_x, min_y, max_y) {
            if mx.is_finite() && mxx.is_finite() && my.is_finite() && mxy.is_finite() {
                return Ok(BoundingBox::new(mx, my, mxx, mxy));
            }
        }

        tracing::warn!(
            "ANALYSIS: Zero-Node Collapse detected or incomplete bounds. Falling back to default empty bounding box."
        );
        Ok(BoundingBox::default())
    }

    pub async fn get_node(&self, table: String, key: String) -> Result<Option<Nodes>> {
        let fetch_fields = Nodes::fetch_fields_for_table(&table);
        let query_str = if fetch_fields.is_empty() {
            "SELECT * FROM $id".to_string()
        } else {
            format!("SELECT * FROM $id FETCH {}", fetch_fields.join(", "))
        };

        let mut res = self
            .db
            .query(query_str)
            .bind(("id", RecordId::new(table.clone(), key)))
            .await?;
        let val: Option<Value> = res.take(0)?;

        if let Some(v) = val {
            let node = Nodes::from_struct_value(&table, v)?;
            return Ok(Some(node));
        }
        Ok(None)
    }

    pub async fn fetch_table_nodes<N, F>(&self) -> Result<Vec<N>>
    where
        N: IsTable + From<(String, F)>,
        F: surrealdb::types::SurrealValue,
    {
        let table = N::LABEL;
        let fetch_fields = N::FETCH_FIELDS;
        let query_str = if fetch_fields.is_empty() {
            format!("SELECT * FROM {}", table)
        } else {
            format!("SELECT * FROM {} FETCH {}", table, fetch_fields.join(", "))
        };

        let mut res = self.db.query(query_str).await?;
        let raw: Vec<Value> = res.take(0)?;

        let nodes = raw
            .into_iter()
            .filter_map(|val| {
                let record = Record::from_record_value(val)?;
                let (key, fields) = record.to_type::<F>()?;
                Some(N::from((key, fields)))
            })
            .collect();

        Ok(nodes)
    }

    pub async fn get_graph_snapshot(&self) -> Result<GraphSnapshot> {
        tracing::info!("Fetching graph snapshot...");

        let mut nodes = Vec::new();
        for &table in Nodes::TABLES {
            tracing::debug!("Fetching {}...", table);
            let fetch_fields = Nodes::fetch_fields_for_table(table);
            let query_str = if fetch_fields.is_empty() {
                format!("SELECT * FROM {}", table)
            } else {
                format!("SELECT * FROM {} FETCH {}", table, fetch_fields.join(", "))
            };

            let mut res = self.db.query(query_str).await?;
            let raw: Vec<Value> = res.take(0)?;

            for val in raw {
                match Nodes::from_struct_value(table, val) {
                    Ok(node) => nodes.push(node),
                    Err(e) => tracing::error!(
                        "Failed to parse node from table {}: {:?}",
                        table,
                        e
                    ),
                }
            }
        }

        tracing::debug!("Fetching IRelations...");
        let relations_raw: Vec<Value> = self.db.select(IRelation::LABEL).await?;
        let relations: Vec<IRelation> = relations_raw
            .into_iter()
            .filter_map(|val| IRelation::from_value(val).ok())
            .collect();
        tracing::debug!("Fetched {} IRelations", relations.len());

        tracing::debug!("Fetching MapMetadata...");
        let metadata: Option<MapData> = self.db.select((MapData::LABEL, MapData::KEY)).await?;
        let metadata = metadata.ok_or_else(|| anyhow::anyhow!("MapMetadata not found"))?;

        Ok(GraphSnapshot {
            nodes,
            relations,
            metadata,
        })
    }

    /// Clear all graph-related tables in the correct dependency order.
    /// This helper works with any handle that derefs to `Surreal<C>` (including a transaction).
    async fn clear_graph(&self) -> Result<()> {
        tracing::debug!("Clearing existing graph data...");

        let db = self.db.clone();
        let tx = db.begin().await?;

        tracing::debug!("Deleting existing IRelations...");
        let _: Vec<Value> = tx.delete(IRelation::LABEL).await?;
        tracing::debug!("Deleted all IRelations");

        for &table in Nodes::TABLES {
            tracing::debug!("Deleting existing {}...", table);
            let _: Vec<Value> = tx.delete(table).await?;
            tracing::debug!("Deleted all {}", table);
        }

        tracing::debug!("Deleting existing MapMetadata...");
        let _: Vec<Value> = tx.delete(MapData::LABEL).await?;
        tracing::debug!("Deleted all MapMetadata");

        tx.commit().await?;
        tracing::debug!("Graph cleared.");
        Ok(())
    }

    pub async fn set_graph_snapshot(&self, snapshot: GraphSnapshot) -> Result<()> {
        tracing::info!("Storing graph snapshot atomically...");

        self.clear_graph().await?;
        let db = self.db.clone();
        let tx = db.begin().await?;

        tracing::debug!("Inserting {} nodes...", snapshot.nodes.len());
        for node in snapshot.nodes {
            let (table, key) = {
                let (t, k) = node.table_and_key();
                (t, k.to_string())
            };
            let document = node.serialize_node();
            let _: Option<Value> = tx.create((table, key)).content(document).await?;
        }

        tracing::debug!("Inserting {} IRelations...", snapshot.relations.len());
        for relation in snapshot.relations {
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

        tracing::debug!("Inserting MapMetadata...");
        let _: Option<MapData> = tx
            .create((MapData::LABEL, MapData::KEY))
            .content(snapshot.metadata)
            .await?;

        tx.commit().await?;
        tracing::info!("Graph snapshot stored successfully.");

        Ok(())
    }

    pub async fn update_node<N>(&self, input: N) -> Result<()>
    where
        N: IsNode,
    {
        let table = input.table_name();
        let key = input.key().to_string();
        let val = input.serialize_node();
        let _: Option<Value> = self
            .db
            .update((table, key.clone()))
            .content(val)
            .await?;
        info!("REPO: Updated Node of table {} with ID: {}", table, key);
        Ok(())
    }

    pub async fn delete_node(&self, table: String, key: String) -> Result<()> {
        let query = "
            BEGIN TRANSACTION;
            DELETE IRelation WHERE in = $target OR out = $target;
            DELETE $target;
            COMMIT TRANSACTION;
        ";
        let record_id = RecordId::new(table, key);
        tracing::trace!(
            "REPO: BEGIN TRANSACTION for cascading delete of {:?}",
            record_id
        );
        self.db
            .query(query)
            .bind(("target", record_id.clone()))
            .await?;

        Ok(())
    }

    pub async fn get_relation(&self, table: String, key: String) -> Result<IRelation> {
        let record_id = RecordId::new(table, key.clone());
        let val: Option<Value> = self.db.select(record_id).await?;
        let val = val.ok_or_else(|| anyhow::anyhow!("Relation not found"))?;
        IRelation::from_value(val).map_err(|e| anyhow::anyhow!("Failed to parse Relation: {}", e))
    }

    pub async fn delete_relation(&self, table: String, key: String) -> Result<()> {
        let record_id = RecordId::new(table, key);
        let _: Option<Value> = self.db.delete(record_id).await?;
        Ok(())
    }

    pub async fn update_relation(
        &self,
        table: String,
        key: String,
        fields: IRelationFields,
    ) -> Result<()> {
        debug!("REPO: update_relation called for {} ", key);
        let record_id = RecordId::new(table, key);
        debug!("REPO: Parsed relation RecordID: {:?}", record_id);

        let _: Option<Value> = self.db.update(record_id).merge(fields.into_value()).await?;
        Ok(())
    }

    pub async fn reroute_relation(
        &self,
        record_string: RecordStrings,
        from: RecordStrings,
        to: RecordStrings,
    ) -> Result<()> {
        let existing = self
            .get_relation(record_string.table.clone(), record_string.key.clone())
            .await?;

        let old_in_id = existing.in_.clone();
        let old_out_id = existing.out.clone();

        let mut updated = existing;
        updated.in_ = from;
        updated.out = to;

        let _: Option<Value> = self.db.delete(record_string.into_record()).await?;

        self.create_relation(updated).await?;

        self.trigger_significance_update(&old_in_id).await?;
        self.trigger_significance_update(&old_out_id).await?;

        Ok(())
    }

    pub async fn patch_entity(&self, id: RecordId, patch: &EntityPatch) -> Result<()> {
        match patch {
            EntityPatch::Node(patches) => {
                for node_patch in patches {
                    self.patch_node(id.clone(), node_patch).await?;
                }
                Ok(())
            }
            EntityPatch::Relation(patches) => {
                for rel_patch in patches {
                    self.patch_relation(id.clone(), rel_patch).await?;
                }
                Ok(())
            }
            EntityPatch::CreateNode(node, relations) => {
                let (table, key) = node.table_and_key();
                if self
                    .get_node(table.to_string(), key.to_string())
                    .await?
                    .is_some()
                {
                    self.update_node(node.clone()).await?;
                } else {
                    self.create_node(node.clone()).await?;
                }
                for rel in relations {
                    self.create_relation(rel.clone()).await?;
                }
                Ok(())
            }
            EntityPatch::DeleteNode(node, _) => {
                let (table, key) = node.table_and_key();
                self.delete_node(table.to_string(), key.to_string()).await?;
                Ok(())
            }
            EntityPatch::CreateRelation(rel) => {
                self.create_relation(rel.clone()).await?;
                Ok(())
            }
            EntityPatch::DeleteRelation(rel) => {
                self.delete_relation(IRelation::LABEL.to_string(), rel.key.clone())
                    .await?;
                Ok(())
            }
        }
    }

    async fn patch_node(&self, id: RecordId, patch: &NodePatch) -> Result<()> {
        let (query_str, bind_val) = match patch {
            NodePatch::Position(coords) => (
                "UPDATE $id SET position = $val",
                coords.clone().into_value(),
            ),
            NodePatch::Size(size) => ("UPDATE $id SET size = $val", size.clone().into_value()),
            NodePatch::Content(content) => (
                "UPDATE $id SET content = $val",
                content.clone().into_value(),
            ),
            NodePatch::IsExpanded(val) => ("UPDATE $id SET is_expanded = $val", Value::Bool(*val)),
            NodePatch::Style(style) => {
                let val = match style {
                    Some(s) => s.clone().into_value(),
                    None => Value::None,
                };
                ("UPDATE $id SET style = $val", val)
            }
            NodePatch::TagOp(op) => match op {
                TagOperation::Add(tag_id) => (
                    "UPDATE $id SET tags += $val",
                    Value::RecordId(RecordId::new(Tag::LABEL, tag_id.clone())),
                ),
                TagOperation::Remove(tag_id) => (
                    "UPDATE $id SET tags -= $val",
                    Value::RecordId(RecordId::new(Tag::LABEL, tag_id.clone())),
                ),
            },
            NodePatch::Significance(sig) => (
                "UPDATE $id SET significance = $val",
                Value::Number(surrealdb::types::Number::from(*sig as i32)),
            ),
        };

        self.db
            .query(query_str)
            .bind(("id", id))
            .bind(("val", bind_val))
            .await?;
        Ok(())
    }

    async fn patch_relation(&self, id: RecordId, patch: &RelationPatch) -> Result<()> {
        let (query_str, bind_val) = match patch {
            RelationPatch::Verb(verb) => {
                ("UPDATE $id SET verb = $val", Value::String(verb.clone()))
            }
            RelationPatch::Style(style) => {
                let val = match style {
                    Some(s) => s.clone().into_value(),
                    None => Value::None,
                };
                ("UPDATE $id SET style = $val", val)
            }
            RelationPatch::Layout(layout) => {
                let val = match layout {
                    Some(l) => l.clone().into_value(),
                    None => Value::None,
                };
                ("UPDATE $id SET layout = $val", val)
            }
            RelationPatch::Directionless(val) => {
                ("UPDATE $id SET directionless = $val", Value::Bool(*val))
            }
        };

        self.db
            .query(query_str)
            .bind(("id", id))
            .bind(("val", bind_val))
            .await?;
        Ok(())
    }

    // --- Tag CRUD ---

    pub async fn create_tag(&self, tag: Tag) -> Result<()> {
        let name_lower = tag.fields.name.to_lowercase();
        let mut res = self
            .db
            .query("SELECT * FROM Tag WHERE string::lowercase(name) = $name")
            .bind(("name", name_lower))
            .await?;
        let existing: Vec<Value> = res.take(0)?;
        if !existing.is_empty() {
            return Err(anyhow::anyhow!("Tag name must be unique"));
        }

        let record_id = RecordId::new(Tag::LABEL, tag.key.clone());
        let _: Option<TagFields> = self.db.create(record_id).content(tag.fields).await?;
        Ok(())
    }

    pub async fn update_tag(&self, tag: Tag) -> Result<()> {
        let name_lower = tag.fields.name.to_lowercase();
        let record_id = RecordId::new(Tag::LABEL, tag.key.clone());
        let mut res = self
            .db
            .query("SELECT * FROM Tag WHERE string::lowercase(name) = $name AND id != $id")
            .bind(("name", name_lower))
            .bind(("id", record_id.clone()))
            .await?;
        let existing: Vec<Value> = res.take(0)?;
        if !existing.is_empty() {
            return Err(anyhow::anyhow!("Tag name must be unique"));
        }

        let _: Option<TagFields> = self.db.update(record_id).content(tag.fields).await?;
        Ok(())
    }

    pub async fn get_tag(&self, key: String) -> Result<Option<Tag>> {
        let record_id = RecordId::new(Tag::LABEL, key.clone());
        let fields: Option<TagFields> = self.db.select(record_id).await?;
        Ok(fields.map(|f| Tag { key, fields: f }))
    }

    pub async fn get_all_tags(&self) -> Result<Vec<Tag>> {
        let tag_records: Vec<Value> = self.db.select(Tag::LABEL).await?;
        let tags: Vec<Tag> = tag_records
            .into_iter()
            .filter_map(|val| {
                let record = Record::from_record_value(val)?;
                let (key, fields) = record.to_type::<TagFields>()?;
                Some(Tag { key, fields })
            })
            .collect();
        Ok(tags)
    }

    pub async fn delete_tag(&self, key: String) -> Result<()> {
        let tag_id = RecordId::new(Tag::LABEL, key);

        // Step 1: Remove the tag RecordId from all INode.tags arrays
        self.db
            .query("UPDATE INode SET tags -= $tag_id WHERE $tag_id INSIDE tags")
            .bind(("tag_id", tag_id.clone()))
            .await?;

        // Step 2: Delete the Tag record itself
        let _: Option<Value> = self.db.delete(tag_id).await?;
        Ok(())
    }

    // --- Template CRUD ---

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

        if nodes.is_empty() {
            return Err(anyhow::anyhow!("Cannot save template from empty selection"));
        }

        // Calculate centroid of selected nodes
        let mut sum_x = 0.0;
        let mut sum_y = 0.0;
        for node in &nodes {
            let pos = node.position();
            sum_x += pos.x as f64;
            sum_y += pos.y as f64;
        }
        let count = nodes.len() as f64;
        let centroid_x = (sum_x / count).round() as i32;
        let centroid_y = (sum_y / count).round() as i32;

        // Shift coordinates relative to (0, 0)
        let mut shifted_nodes = nodes;
        for node in &mut shifted_nodes {
            let pos = node.position_mut();
            pos.x -= centroid_x;
            pos.y -= centroid_y;
        }

        let now = chrono::Utc::now().timestamp_millis();
        let key = uuid::Uuid::new_v4().to_string();

        let template = Template {
            key: key.clone(),
            name,
            created_at: now,
            updated_at: now,
            nodes: shifted_nodes,
            relations,
        };

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

    // --- History & Patch Helpers ---

    pub async fn record_patch_history(
        &self,
        id: RecordStrings,
        forward: EntityPatch,
        reverse: EntityPatch,
    ) -> Result<()> {
        let history_manager = HistoryManager::new(&self.db, 100);
        let history_payload = PatchHistoryPayload {
            id,
            forward,
            reverse,
        };
        history_manager
            .push_event("entity_patch", history_payload.into_value())
            .await?;
        Ok(())
    }

    pub async fn apply_patch_check_position(
        &self,
        id: &RecordStrings,
        patch: &EntityPatch,
    ) -> Result<bool> {
        let record_id = RecordId::new(id.table.as_str(), id.key.as_str());
        self.patch_entity(record_id, patch).await?;

        let has_position_change = match patch {
            EntityPatch::Node(patches) => {
                patches.iter().any(|p| matches!(p, NodePatch::Position(_)))
            }
            EntityPatch::CreateNode(_, _) | EntityPatch::DeleteNode(_, _) => true,
            _ => false,
        };
        Ok(has_position_change)
    }

    pub async fn get_connected_relations(&self, node_key: &str) -> Result<Vec<IRelation>> {
        let relations_raw: Vec<Value> = self.db.select(IRelation::LABEL).await?;
        let mut connected_relations = Vec::new();
        for val in relations_raw {
            if let Ok(rel) = IRelation::from_value(val) {
                if rel.in_.key == node_key || rel.out.key == node_key {
                    connected_relations.push(rel);
                }
            }
        }
        Ok(connected_relations)
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

    pub async fn undo_count(&self) -> Result<u32> {
        let mut response = self
            .db
            .query("SELECT VALUE count() FROM History WHERE status = 'applied' GROUP ALL")
            .await?;
        let count: Vec<i64> = response.take(0)?;
        Ok(count.first().copied().unwrap_or(0) as u32)
    }

    pub async fn redo_count(&self) -> Result<u32> {
        let mut response = self
            .db
            .query("SELECT VALUE count() FROM History WHERE status = 'undone' GROUP ALL")
            .await?;
        let count: Vec<i64> = response.take(0)?;
        Ok(count.first().copied().unwrap_or(0) as u32)
    }

    pub async fn query_search(&self, query: String) -> Result<Vec<Nodes>> {
        tracing::debug!("REPO: query_search called with query: {}", query);
        let trimmed = query.trim();
        let query_str = if trimmed.to_uppercase().starts_with("WHERE") {
            format!("SELECT * FROM INode, TaskNode, InterNode {}", trimmed)
        } else {
            "SELECT * FROM INode, TaskNode WHERE content.text ~ $query".to_string()
        };

        let mut req = self.db.query(&query_str);
        if !trimmed.to_uppercase().starts_with("WHERE") {
            req = req.bind(("query", query));
        }

        let mut res = req.await?;
        let records: Vec<Value> = res.take(0)?;
        let mut nodes = Vec::new();

        for val in records {
            if let Value::Object(ref obj) = val {
                if let Some(Value::RecordId(rid)) = obj.get("id") {
                    let table = rid.table.clone();
                    if let Ok(node) = Nodes::from_struct_value(&table, val) {
                        nodes.push(node);
                    }
                }
            }
        }

        Ok(nodes)
    }

    pub async fn undo_event(&self) -> Result<Option<HistoryRecord>> {
        let history_manager = HistoryManager::new(&self.db, 100);
        history_manager.undo().await
    }

    pub async fn redo_event(&self) -> Result<Option<HistoryRecord>> {
        let history_manager = HistoryManager::new(&self.db, 100);
        history_manager.redo().await
    }
}
