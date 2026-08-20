use crate::domain::id::TypedRecordId;
pub use crate::domain::types::TableKind;
use uuid::Uuid;

#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
pub enum TableCategory {
    Node,
    Relation,
    Auxiliary,
}

pub trait SurrealDbEnum: Sized + Copy {
    fn to_u8(&self) -> u8;
    fn from_u8(val: u8) -> Result<Self, anyhow::Error>;
    fn to_surreal_str(&self) -> &'static str;
    fn from_surreal_bytes(bytes: &[u8]) -> Result<Self, anyhow::Error>;
}

/// Base trait implemented by ALL database structs in Centrode.
pub trait SurrealTable {
    const KIND: TableKind;
    const FETCH_FIELDS: &'static [&'static str] = &[];

    fn get_key(&self) -> &Uuid;

    fn get_record_id(&self) -> TypedRecordId {
        TypedRecordId::new(Self::KIND, *self.get_key())
    }
}

/// Marker trait implemented by all canvas node structs.
pub trait NodeEntity: SurrealTable {}

/// Marker trait implemented by relation edge structs.
pub trait RelationEntity: SurrealTable {}

/// Marker trait implemented by non-graph workspace & system structs.
pub trait AuxiliaryEntity: SurrealTable {}
