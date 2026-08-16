use crate::domain::id::TypedRecordId;
use crate::domain::nodes::IsNode;
use crate::domain::patches::{
    EntityPatch, NodePatch, RelationPatch, TagOperation,
};
use crate::domain::traits::SurrealDbEnum;
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
                if self
                    .get_node(node.id().clone())
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
                self.delete_node(node.id().clone()).await?;
                Ok(())
            }
            EntityPatch::CreateRelation(rel) => {
                self.create_relation(rel.clone()).await?;
                Ok(())
            }
            EntityPatch::DeleteRelation(rel) => {
                self.delete_relation(rel.key).await?;
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
                let typed_id = TypedRecordId::from_value(Value::RecordId(id.clone()))?;
                let existing = self.get_relation(typed_id).await?;
                let old_in_id = existing.in_.clone();
                let old_out_id = existing.out.clone();
                let mut updated = existing;
                updated.in_ = in_id.clone();
                updated.out = out_id.clone();
                let _: Option<Value> = self.db.delete(id).await?;
                self.create_relation(updated).await?;
                self.trigger_significance_update(&old_in_id).await?;
                self.trigger_significance_update(&old_out_id).await?;
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
            RelationPatch::Direction(val) => {
                ("UPDATE $id SET direction = $val", val.clone().into_value())
            }
            RelationPatch::RoutingMode(mode) => (
                "UPDATE $id SET layout.routing_mode = $val",
                mode.clone().into_value(),
            ),
            RelationPatch::PortSides(from_side, to_side) => {
                self.db
                    .query("UPDATE $id SET layout.from_side = $fs, layout.to_side = $ts")
                    .bind(("id", id))
                    .bind(("fs", from_side.map(|s| s.into_value()).unwrap_or(Value::None)))
                    .bind(("ts", to_side.map(|s| s.into_value()).unwrap_or(Value::None)))
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
}
