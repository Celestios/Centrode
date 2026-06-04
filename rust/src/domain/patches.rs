use crate::domain::base_models::{Coordinates, RecordStrings, Size};
use crate::domain::contents::Content;
use crate::domain::styles::{NodeStyle, RelationLayout, RelationStyle};
use crate::domain::nodes::Nodes;
use crate::domain::relations::IRelation;
use surrealdb::types::SurrealValue;

#[derive(Debug, Clone, SurrealValue)]
pub enum TagOperation {
    Add(String),
    Remove(String),
}

#[derive(Debug, Clone, SurrealValue)]
pub enum NodePatch {
    Position(Coordinates),
    Size(Size),
    Content(Content),
    IsExpanded(bool),
    Style(Option<NodeStyle>),
    TagOp(TagOperation),
    Significance(u8),
}

#[derive(Debug, Clone, SurrealValue)]
pub enum RelationPatch {
    Verb(String),
    Style(Option<RelationStyle>),
    Layout(Option<RelationLayout>),
    Directionless(bool),
}

#[derive(Debug, Clone, SurrealValue)]
pub enum EntityPatch {
    Node(Vec<NodePatch>),
    Relation(Vec<RelationPatch>),
    CreateNode(Nodes, Vec<IRelation>),
    DeleteNode(Nodes, Vec<IRelation>),
    CreateRelation(IRelation),
    DeleteRelation(IRelation),
}

#[derive(Debug, Clone, SurrealValue)]
pub struct SymmetricEntityPatch {
    pub id: RecordStrings,
    pub forward: EntityPatch,
    pub reverse: EntityPatch,
}

pub type PatchHistoryPayload = SymmetricEntityPatch;

