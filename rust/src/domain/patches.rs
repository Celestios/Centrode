use crate::domain::base_models::{Coordinates, Size};
use crate::domain::contents::Content;
use crate::domain::id::TypedRecordId;
use crate::domain::nodes::{BrushType, IsNode, MediaType, Nodes, ShapeType, TaskState};
use crate::domain::relations::IRelation;
use crate::domain::styles::{NodeStyle, PortSide, RelationDirection, RelationLayout, RelationStyle};
use crate::relation_engine::config::RoutingMode;
use flutter_rust_bridge::frb;
use surrealdb::types::{SurrealValue, Value};

/// Atomic composite mutation set representing forward or inverse cascade deltas
#[frb]
#[derive(Debug, Clone, Default)]
pub struct GraphDelta {
    /// Patch existing nodes (undo/redo cascades)
    pub node_upserts: Vec<(TypedRecordId, Vec<NodePatch>)>,
    /// Create brand-new nodes (template instantiation)
    pub node_creations: Vec<Nodes>,
    pub node_deletions: Vec<TypedRecordId>,
    /// Patch existing relations
    pub relation_upserts: Vec<(TypedRecordId, Vec<RelationPatch>)>,
    /// Create brand-new relations
    pub relation_creations: Vec<IRelation>,
    pub relation_deletions: Vec<TypedRecordId>,
}

#[frb]
#[derive(Debug, Clone, SurrealValue)]
pub enum TagOperation {
    Add(TypedRecordId),
    Remove(TypedRecordId),
}

#[frb]
#[derive(Debug, Clone)]
pub enum NodePatch {
    Position(Coordinates),
    Size(Size),
    Content(Content),
    IsExpanded(bool),
    Style(Option<NodeStyle>),
    TagOp(TagOperation),
    Significance(u8),
    TaskState(TaskState),
    ShapeType(ShapeType),
    BrushType(BrushType),
    MediaType(MediaType),
    SourceUrl(Option<String>),
    Title(String),
    Verb(String),
}

impl SurrealValue for NodePatch {
    fn kind_of() -> surrealdb::types::Kind {
        surrealdb::types::Kind::Either(vec![surrealdb::types::Kind::Object])
    }

    fn into_value(self) -> Value {
        let mut map = std::collections::BTreeMap::new();
        match self {
            NodePatch::Position(v) => {
                map.insert("Position".to_string(), v.into_value());
            }
            NodePatch::Size(v) => {
                map.insert("Size".to_string(), v.into_value());
            }
            NodePatch::Content(v) => {
                map.insert("Content".to_string(), v.into_value());
            }
            NodePatch::IsExpanded(v) => {
                map.insert("IsExpanded".to_string(), Value::Bool(v));
            }
            NodePatch::Style(v) => {
                let val = match v {
                    Some(s) => s.into_value(),
                    None => Value::None,
                };
                map.insert("Style".to_string(), val);
            }
            NodePatch::TagOp(v) => {
                map.insert("TagOp".to_string(), v.into_value());
            }
            NodePatch::Significance(v) => {
                map.insert(
                    "Significance".to_string(),
                    Value::Number(surrealdb::types::Number::from(v as i32)),
                );
            }
            NodePatch::TaskState(v) => {
                map.insert("TaskState".to_string(), v.into_value());
            }
            NodePatch::ShapeType(v) => {
                map.insert("ShapeType".to_string(), v.into_value());
            }
            NodePatch::BrushType(v) => {
                map.insert("BrushType".to_string(), v.into_value());
            }
            NodePatch::MediaType(v) => {
                map.insert("MediaType".to_string(), v.into_value());
            }
            NodePatch::SourceUrl(v) => {
                let val = match v {
                    Some(u) => Value::String(u),
                    None => Value::None,
                };
                map.insert("SourceUrl".to_string(), val);
            }
            NodePatch::Title(v) => {
                map.insert("Title".to_string(), Value::String(v));
            }
            NodePatch::Verb(v) => {
                map.insert("Verb".to_string(), Value::String(v));
            }
        }
        Value::Object(map.into())
    }

    fn from_value(value: Value) -> Result<Self, surrealdb::types::Error> {
        match value {
            Value::Object(obj) => {
                let map = obj.into_inner();
                if let Some(v) = map.get("Position") {
                    return Ok(NodePatch::Position(Coordinates::from_value(v.clone())?));
                }
                if let Some(v) = map.get("Size") {
                    return Ok(NodePatch::Size(Size::from_value(v.clone())?));
                }
                if let Some(v) = map.get("Content") {
                    return Ok(NodePatch::Content(Content::from_value(v.clone())?));
                }
                if let Some(v) = map.get("IsExpanded") {
                    return Ok(NodePatch::IsExpanded(bool::from_value(v.clone())?));
                }
                if let Some(v) = map.get("Style") {
                    if matches!(v, Value::None | Value::Null) {
                        return Ok(NodePatch::Style(None));
                    }
                    return Ok(NodePatch::Style(Some(NodeStyle::from_value(v.clone())?)));
                }
                if let Some(v) = map.get("TagOp") {
                    return Ok(NodePatch::TagOp(TagOperation::from_value(v.clone())?));
                }
                if let Some(v) = map.get("Significance") {
                    let sig = u8::from_value(v.clone())?;
                    return Ok(NodePatch::Significance(sig));
                }
                if let Some(v) = map.get("TaskState") {
                    return Ok(NodePatch::TaskState(TaskState::from_value(v.clone())?));
                }
                if let Some(v) = map.get("ShapeType") {
                    return Ok(NodePatch::ShapeType(ShapeType::from_value(v.clone())?));
                }
                if let Some(v) = map.get("BrushType") {
                    return Ok(NodePatch::BrushType(BrushType::from_value(v.clone())?));
                }
                if let Some(v) = map.get("MediaType") {
                    return Ok(NodePatch::MediaType(MediaType::from_value(v.clone())?));
                }
                if let Some(v) = map.get("SourceUrl") {
                    if matches!(v, Value::None | Value::Null) {
                        return Ok(NodePatch::SourceUrl(None));
                    }
                    return Ok(NodePatch::SourceUrl(Some(String::from_value(v.clone())?)));
                }
                if let Some(v) = map.get("Title") {
                    return Ok(NodePatch::Title(String::from_value(v.clone())?));
                }
                if let Some(v) = map.get("Verb") {
                    return Ok(NodePatch::Verb(String::from_value(v.clone())?));
                }
                if map.is_empty() {
                    return Ok(NodePatch::Style(None));
                }
                Err(surrealdb::types::Error::thrown(format!(
                    "Failed to decode NodePatch from map: {:?}",
                    map
                )))
            }
            unsupported => Err(surrealdb::types::Error::thrown(format!(
                "Expected Object for NodePatch, found: {:?}",
                unsupported
            ))),
        }
    }
}

#[frb]
#[derive(Debug, Clone, SurrealValue)]
pub enum RelationPatch {
    Verb(String),
    Endpoints(TypedRecordId, TypedRecordId),
    Style(Option<RelationStyle>),
    Layout(Option<RelationLayout>),
    Direction(RelationDirection),
    RoutingMode(RoutingMode),
    PortSides(Option<PortSide>, Option<PortSide>),
}

#[frb]
#[derive(Debug, Clone, SurrealValue)]
pub enum EntityPatch {
    Node(Vec<NodePatch>),
    Relation(Vec<RelationPatch>),
    CreateNode(Nodes, Vec<IRelation>),
    DeleteNode(Nodes, Vec<IRelation>),
    CreateRelation(IRelation),
    DeleteRelation(IRelation),
}

#[frb]
#[derive(Debug, Clone, SurrealValue)]
pub struct SymmetricEntityPatch {
    pub id: TypedRecordId,
    pub forward: EntityPatch,
    pub reverse: EntityPatch,
}

impl SymmetricEntityPatch {
    pub fn to_inverse_graph_delta(&self) -> GraphDelta {
        entity_patch_to_graph_delta(&self.id, &self.reverse)
    }

    pub fn to_forward_graph_delta(&self) -> GraphDelta {
        entity_patch_to_graph_delta(&self.id, &self.forward)
    }
}

fn entity_patch_to_graph_delta(entity_id: &TypedRecordId, patch: &EntityPatch) -> GraphDelta {
    match patch {
        EntityPatch::Node(patches) => GraphDelta {
            node_upserts: vec![(entity_id.clone(), patches.clone())],
            ..Default::default()
        },
        EntityPatch::Relation(patches) => GraphDelta {
            relation_upserts: vec![(entity_id.clone(), patches.clone())],
            ..Default::default()
        },
        EntityPatch::CreateNode(node, relations) => GraphDelta {
            node_creations: vec![node.clone()],
            relation_creations: relations.clone(),
            ..Default::default()
        },
        EntityPatch::DeleteNode(node, relations) => GraphDelta {
            node_deletions: vec![*node.id()],
            relation_deletions: relations.iter().map(|r| r.key).collect(),
            ..Default::default()
        },
        EntityPatch::CreateRelation(rel) => GraphDelta {
            relation_creations: vec![rel.clone()],
            ..Default::default()
        },
        EntityPatch::DeleteRelation(rel) => GraphDelta {
            relation_deletions: vec![rel.key],
            ..Default::default()
        },
    }
}
