use crate::base_models::MapData;
use crate::nodes::Nodes;
use crate::relations::IRelation;
use centrode_macros::SurrealDbEnum;

#[repr(u8)]
#[derive(Copy, Clone, Debug, PartialEq, Eq, Hash, SurrealDbEnum)]
pub enum HistoryStatus {
    Applied = 0,
    Undone = 1,
}

#[derive(Debug, Clone)]
pub struct GraphSnapshot {
    pub nodes: Vec<Nodes>,
    pub relations: Vec<IRelation>,
    pub metadata: MapData,
}