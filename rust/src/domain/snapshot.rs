use crate::domain::base_models::MapData;
use crate::domain::nodes::Nodes;
use crate::domain::relations::IRelation;

#[derive(Debug, Clone)]
pub struct GraphSnapshot {
    pub nodes: Vec<Nodes>,
    pub relations: Vec<IRelation>,
    pub metadata: MapData,
}