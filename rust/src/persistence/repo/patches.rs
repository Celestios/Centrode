use crate::domain::id::TypedRecordId;
use crate::domain::patches::{
    EntityPatch, NodePatch, RelationPatch, SymmetricEntityPatch, TagOperation,
};
use crate::domain::relations::IRelation;
use crate::domain::tags::Tag;
use crate::domain::traits::SurrealDbEnum;
use crate::persistence::history::{HistoryManager, HistoryRecord};
use crate::persistence::repo::Repository;

use anyhow::Result;
use surrealdb::types::{RecordId, SurrealValue, Value};

impl Repository {
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
                self.delete_relation(IRelation::LABEL.to_string(), rel.key.key.to_string())
                    .await?;
                Ok(())
            }
        }
    }

    pub async fn patch_node(&self, id: RecordId, patch: &NodePatch) -> Result<()> {
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
                    tag_id.into_value(),
                ),
                TagOperation::Remove(tag_id) => (
                    "UPDATE $id SET tags -= $val",
                    tag_id.into_value(),
                ),
            },
            NodePatch::Significance(sig) => (
                "UPDATE $id SET significance = $val",
                Value::Number(surrealdb::types::Number::from(*sig as i32)),
            ),
            NodePatch::TaskState(state) => (
                "UPDATE $id SET state = $val",
                Value::String(state.to_surreal_str().to_string()),
            ),
            NodePatch::ShapeType(shape) => (
                "UPDATE $id SET shape_type = $val",
                Value::String(shape.to_surreal_str().to_string()),
            ),
            NodePatch::BrushType(brush) => (
                "UPDATE $id SET brush_type = $val",
                Value::String(brush.to_surreal_str().to_string()),
            ),
            NodePatch::MediaType(media) => (
                "UPDATE $id SET media_type = $val",
                Value::String(media.to_surreal_str().to_string()),
            ),
            NodePatch::SourceUrl(url) => {
                let val = match url {
                    Some(u) => Value::String(u.clone()),
                    None => Value::None,
                };
                ("UPDATE $id SET source_url = $val", val)
            }
            NodePatch::Title(title) => (
                "UPDATE $id SET title = $val",
                Value::String(title.clone()),
            ),
            NodePatch::Verb(verb) => (
                "UPDATE $id SET verb = $val",
                Value::String(verb.clone()),
            ),
        };

        self.db
            .query(query_str)
            .bind(("id", id))
            .bind(("val", bind_val))
            .await?;
        Ok(())
    }

    pub async fn patch_relation(&self, id: RecordId, patch: &RelationPatch) -> Result<()> {
        let (query_str, bind_val) = match patch {
            RelationPatch::Verb(verb) => (
                "UPDATE $id SET verb = $val",
                Value::String(verb.clone()),
            ),
            RelationPatch::Endpoints(in_id, out_id) => {
                self.db
                    .query("UPDATE $id SET in = $in_val, out = $out_val")
                    .bind(("id", id))
                    .bind(("in_val", in_id.into_value()))
                    .bind(("out_val", out_id.into_value()))
                    .await?;
                return Ok(());
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
            RelationPatch::RoutingMode(mode) => (
                "UPDATE $id SET layout.routing_mode = $val",
                mode.clone().into_value(),
            ),
            RelationPatch::PortSides(from_side, to_side) => {
                self.db
                    .query("UPDATE $id SET layout.from_side = $fs, layout.to_side = $ts")
                    .bind(("id", id))
                    .bind(("fs", from_side.map(|s| Value::String(s.to_surreal_str().to_string())).unwrap_or(Value::None)))
                    .bind(("ts", to_side.map(|s| Value::String(s.to_surreal_str().to_string())).unwrap_or(Value::None)))
                    .await?;
                return Ok(());
            }
        };

        self.db
            .query(query_str)
            .bind(("id", id))
            .bind(("val", bind_val))
            .await?;
        Ok(())
    }

    pub async fn record_patch_history(
        &self,
        id: TypedRecordId,
        forward: EntityPatch,
        reverse: EntityPatch,
    ) -> Result<()> {
        let history_manager = HistoryManager::new(&self.db, 100);
        let history_payload = SymmetricEntityPatch {
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
        id: &TypedRecordId,
        patch: &EntityPatch,
    ) -> Result<bool> {
        let record_id = id.to_record_id();
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

    pub async fn undo_event(&self) -> Result<Option<HistoryRecord>> {
        let history_manager = HistoryManager::new(&self.db, 100);
        history_manager.undo().await
    }

    pub async fn redo_event(&self) -> Result<Option<HistoryRecord>> {
        let history_manager = HistoryManager::new(&self.db, 100);
        history_manager.redo().await
    }
}
