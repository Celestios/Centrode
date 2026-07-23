use crate::domain::traits::TableKind;
use surrealdb::types::{RecordId, RecordIdKey, SurrealValue, Value};
use uuid::Uuid;

/// Unified record identifier across all tiers. 17 bytes on stack, 0 heap allocations.
#[repr(C)]
#[derive(Copy, Clone, Debug, PartialEq, Eq, Hash)]
pub struct TypedRecordId {
    pub table: TableKind,
    pub key: Uuid,
}

// 1. Stack Memory Footprint Invariant (17 bytes)
const _: () = assert!(std::mem::size_of::<TypedRecordId>() == 17);

impl TypedRecordId {
    #[inline]
    pub const fn new(table: TableKind, key: Uuid) -> Self {
        Self { table, key }
    }

    #[inline]
    pub fn new_v4(table: TableKind) -> Self {
        Self::new(table, Uuid::new_v4())
    }

    #[inline]
    pub fn to_record_id(&self) -> RecordId {
        RecordId::new(self.table.table_name(), RecordIdKey::Uuid(self.key.into()))
    }

    #[inline]
    pub fn into_record(&self) -> RecordId {
        self.to_record_id()
    }

    /// Zero-allocation 17-byte binary pack: [1-byte TableKind, 16-byte UUID key]
    #[inline]
    pub fn to_bytes(&self) -> [u8; 17] {
        let mut bytes = [0u8; 17];
        bytes[0] = self.table as u8;
        bytes[1..17].copy_from_slice(self.key.as_bytes());
        bytes
    }

    #[inline]
    pub fn from_bytes(bytes: &[u8; 17]) -> Result<Self, anyhow::Error> {
        let table = TableKind::try_from(bytes[0])?;
        let key = Uuid::from_slice(&bytes[1..17])?;
        Ok(Self { table, key })
    }
}

impl From<TypedRecordId> for RecordIdKey {
    fn from(id: TypedRecordId) -> Self {
        RecordIdKey::Uuid(id.key.into())
    }
}

impl From<&TypedRecordId> for RecordIdKey {
    fn from(id: &TypedRecordId) -> Self {
        RecordIdKey::Uuid(id.key.into())
    }
}

impl std::fmt::Display for TypedRecordId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}:{}", self.table.table_name(), self.key)
    }
}

impl SurrealValue for TypedRecordId {
    fn kind_of() -> surrealdb::types::Kind {
        surrealdb::types::Kind::Record(vec![])
    }

    fn into_value(self) -> Value {
        self.to_record_id().into_value()
    }

    fn from_value(value: Value) -> Result<Self, surrealdb::types::Error> {
        match value {
            Value::RecordId(rid) => {
                let table = TableKind::from_table_name(rid.table.as_str())
                    .map_err(|e| surrealdb::types::Error::thrown(e.to_string()))?;
                match rid.key {
                    RecordIdKey::Uuid(u) => Ok(Self::new(table, *u)),
                    unsupported => Err(surrealdb::types::Error::thrown(format!(
                        "Expected UUID key for TypedRecordId, found: {:?}",
                        unsupported
                    ))),
                }
            }
            unsupported => Err(surrealdb::types::Error::thrown(format!(
                "Expected RecordId for TypedRecordId, found: {:?}",
                unsupported
            ))),
        }
    }
}
