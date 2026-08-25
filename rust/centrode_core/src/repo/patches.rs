use crate::domain::id::TypedRecordId;
use crate::domain::nodes::IsNode;
use crate::domain::patches::{
    EntityPatch, NodePatch, RelationPatch, TagOperation,
};
use crate::domain::traits::SurrealDbEnum;
use crate::repo::analysis::SurrealLayoutRepository;
use crate::repo::nodes::SurrealNodeRepository;
use crate::repo::relations::SurrealRelationRepository;
use crate::repo::traits::{LayoutRepository, NodeRepository, RelationRepository};

use anyhow::Result;
use surrealdb::engine::local::Db;
use surrealdb::types::{RecordId, SurrealValue, Value};
use surrealdb::Surreal;

pub(crate) async fn patch_entity_db(db: &Surreal<Db>, id: RecordId, patch: &EntityPatch) -> Result<()> {
    let node_repo = SurrealNodeRepository::new(db.clone());
    let rel_repo = SurrealRelationRepository::new(db.clone());

    match patch {
        EntityPatch::Node(patches) => {
            for node_patch in patches {
                node_repo.patch_node(id.clone(), node_patch).await?;
            }
            Ok(())
        }
        EntityPatch::Relation(patches) => {
            for rel_patch in patches {
                rel_repo.patch_relation(id.clone(), rel_patch).await?;
            }
            Ok(())
        }
        EntityPatch::CreateNode(node, relations) => {
            if node_repo
                .get_node(node.id().clone())
                .await?
                .is_some()
            {
                node_repo.update_node(node.clone()).await?;
            } else {
                node_repo.create_node(node.clone()).await?;
            }
            for rel in relations {
                rel_repo.create_relation(rel.clone()).await?;
            }
            Ok(())
        }
        EntityPatch::DeleteNode(node, _) => {
            node_repo.delete_node(node.id().clone()).await?;
            Ok(())
        }
        EntityPatch::CreateRelation(rel) => {
            rel_repo.create_relation(rel.clone()).await?;
            Ok(())
        }
        EntityPatch::DeleteRelation(rel) => {
            rel_repo.delete_relation(rel.key).await?;
            Ok(())
        }
    }
}

pub(crate) async fn patch_node_db(db: &Surreal<Db>, id: RecordId, patch: &NodePatch) -> Result<()> {
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
        NodePatch::Attachment(att) => (
            "UPDATE $id SET attachment = $val",
            att.clone().into_value(),
        ),
        NodePatch::Attachments(atts) => (
            "UPDATE $id SET attachments = $val",
            atts.clone().into_value(),
        ),
        NodePatch::Title(title) => (
            "UPDATE $id SET title = $val",
            Value::String(title.clone()),
        ),
        NodePatch::Verb(verb) => (
            "UPDATE $id SET verb = $val",
            Value::String(verb.clone()),
        ),
    };

    db.query(query_str)
        .bind(("id", id))
        .bind(("val", bind_val))
        .await?;
    Ok(())
}

pub(crate) async fn patch_relation_db(db: &Surreal<Db>, id: RecordId, patch: &RelationPatch) -> Result<()> {
    let rel_repo = SurrealRelationRepository::new(db.clone());
    let layout_repo = SurrealLayoutRepository::new(db.clone());

    let (query_str, bind_val) = match patch {
        RelationPatch::Verb(verb) => (
            "UPDATE $id SET verb = $val",
            Value::String(verb.clone()),
        ),
        RelationPatch::Endpoints(in_id, out_id) => {
            let typed_id = TypedRecordId::from_value(Value::RecordId(id.clone()))?;
            let existing = rel_repo.get_relation(typed_id).await?;
            let old_in_id = existing.in_.clone();
            let old_out_id = existing.out.clone();
            let mut updated = existing;
            updated.in_ = in_id.clone();
            updated.out = out_id.clone();
            let _: Option<Value> = db.delete(id).await?;
            rel_repo.create_relation(updated).await?;
            layout_repo.trigger_significance_update(&old_in_id).await?;
            layout_repo.trigger_significance_update(&old_out_id).await?;
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
            db.query("UPDATE $id SET layout.from_side = $fs, layout.to_side = $ts")
                .bind(("id", id))
                .bind(("fs", from_side.map(|s| s.into_value()).unwrap_or(Value::None)))
                .bind(("ts", to_side.map(|s| s.into_value()).unwrap_or(Value::None)))
                .await?;
            return Ok(());
        }
    };

    db.query(query_str)
        .bind(("id", id))
        .bind(("val", bind_val))
        .await?;
    Ok(())
}

pub(crate) async fn apply_patch_check_position_db(
    db: &Surreal<Db>,
    id: &TypedRecordId,
    patch: &EntityPatch,
) -> Result<bool> {
    let record_id = id.to_record_id();
    patch_entity_db(db, record_id, patch).await?;

    let has_position_change = match patch {
        EntityPatch::Node(patches) => {
            patches.iter().any(|p| matches!(p, NodePatch::Position(_)))
        }
        EntityPatch::CreateNode(_, _) | EntityPatch::DeleteNode(_, _) => true,
        _ => false,
    };
    Ok(has_position_change)
}
