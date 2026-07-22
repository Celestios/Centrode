use crate::domain::id::TypedRecordId;
use crate::domain::traits::TableKind;
use uuid::Uuid;

// 1. Stack Memory Footprint Invariant
const _: () = assert!(std::mem::size_of::<TypedRecordId>() == 17);

#[test]
fn test_typed_record_id_binary_roundtrip() {
    let original = TypedRecordId::new(TableKind::TaskNode, Uuid::new_v4());
    let bytes = original.to_bytes();
    assert_eq!(bytes.len(), 17);
    let decoded = TypedRecordId::from_bytes(&bytes).expect("Failed to decode TypedRecordId");
    assert_eq!(original, decoded);
}

#[test]
fn test_map_data_table_name_parity() {
    assert_eq!(TableKind::MapData.table_name(), "MapData");
}
