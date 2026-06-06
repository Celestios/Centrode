/// Test whether `#[surrealdb(flatten)]` works for user-land structs.
///
/// If the flatten attribute is supported by the SurrealValue derive macro
/// for external crates, a struct with a nested "base" struct can be flattened
/// into the parent, so that `{ id, created_at, updated_at, name, color }`
/// is a single flat object rather than `{ base: { id, ... }, name, color }`.
///
/// This test exercises three things:
/// 1. Whether the derive compiles at all with `#[surrealdb(flatten)]`
/// 2. Whether `into_value()` produces a flat object (no nested "record_meta" key)
/// 3. Whether `from_value()` can round-trip a flat object back into the struct

use surrealdb::types::{SurrealValue, Value};

// ----- Base record struct we want to share across all models -----
#[derive(Debug, Clone, SurrealValue)]
pub struct RecordMeta {
    pub created_at: i64,
    pub updated_at: i64,
}

// ----- Test model using flatten -----
#[derive(Debug, Clone, SurrealValue)]
pub struct FlatTag {
    #[surreal(flatten)]
    pub record_meta: RecordMeta,
    pub name: String,
    pub color: u32,
}

// ----- Control: same model WITHOUT flatten -----
#[derive(Debug, Clone, SurrealValue)]
pub struct NestedTag {
    pub record_meta: RecordMeta,
    pub name: String,
    pub color: u32,
}

#[test]
fn test_flatten_compiles_and_produces_flat_value() {
    let tag = FlatTag {
        record_meta: RecordMeta {
            created_at: 1000,
            updated_at: 2000,
        },
        name: "TestTag".to_string(),
        color: 0xFF0000,
    };

    let value = tag.into_value();

    // If flatten works, the Value::Object should have top-level keys:
    //   created_at, updated_at, name, color
    // If it does NOT work (nests), it would have:
    //   record_meta: { created_at, updated_at }, name, color
    match &value {
        Value::Object(obj) => {
            // Print all keys for debugging
            let keys: Vec<&String> = obj.keys().collect();
            println!("FlatTag keys: {:?}", keys);

            let has_created_at = obj.contains_key("created_at");
            let has_updated_at = obj.contains_key("updated_at");
            let has_record_meta = obj.contains_key("record_meta");

            println!("has_created_at: {}", has_created_at);
            println!("has_updated_at: {}", has_updated_at);
            println!("has_record_meta (should be false if flatten works): {}", has_record_meta);

            // The main assertion: flatten should produce top-level keys
            assert!(has_created_at, "Flatten should promote created_at to top level");
            assert!(has_updated_at, "Flatten should promote updated_at to top level");
            assert!(!has_record_meta, "Flatten should NOT have a nested record_meta key");
        }
        other => panic!("Expected Value::Object, got: {:?}", other),
    }
}

#[test]
fn test_flatten_roundtrip() {
    let original = FlatTag {
        record_meta: RecordMeta {
            created_at: 1000,
            updated_at: 2000,
        },
        name: "RoundTrip".to_string(),
        color: 42,
    };

    let value = original.clone().into_value();
    let restored = FlatTag::from_value(value).expect("from_value should succeed for flatten struct");

    assert_eq!(restored.record_meta.created_at, 1000);
    assert_eq!(restored.record_meta.updated_at, 2000);
    assert_eq!(restored.name, "RoundTrip");
    assert_eq!(restored.color, 42);
}

#[test]
fn test_nested_control_has_nested_key() {
    let tag = NestedTag {
        record_meta: RecordMeta {
            created_at: 1000,
            updated_at: 2000,
        },
        name: "Control".to_string(),
        color: 0,
    };

    let value = tag.into_value();
    match &value {
        Value::Object(obj) => {
            let keys: Vec<&String> = obj.keys().collect();
            println!("NestedTag keys: {:?}", keys);

            // Without flatten, "record_meta" should exist as a nested object
            assert!(obj.contains_key("record_meta"), "Without flatten, should have nested record_meta");
            assert!(!obj.contains_key("created_at"), "Without flatten, created_at should NOT be at top level");
        }
        other => panic!("Expected Value::Object, got: {:?}", other),
    }
}

// ----- Generic record wrapper test -----
use rust_lib_mycelium::domain::base_models::RecordStrings;

#[derive(Debug, Clone, SurrealValue)]
pub struct GenericRecord<T: SurrealValue> {
    pub id: RecordStrings,
    pub created_at: i64,
    pub updated_at: i64,
    #[surreal(flatten)]
    pub data: T,
}

#[derive(Debug, Clone, SurrealValue, PartialEq, Eq)]
pub struct MockFields {
    pub value: String,
    pub active: bool,
}

#[test]
fn test_generic_record_flatten_roundtrip() {
    let record = GenericRecord {
        id: RecordStrings {
            table: "MockTable".to_string(),
            key: "uuid-123".to_string(),
        },
        created_at: 12345,
        updated_at: 67890,
        data: MockFields {
            value: "Hello".to_string(),
            active: true,
        },
    };

    let value = record.clone().into_value();

    // Verify flattened structure
    if let Value::Object(ref obj) = value {
        assert!(obj.contains_key("id"), "Should contain id");
        assert!(obj.contains_key("created_at"), "Should contain created_at at top-level");
        assert!(obj.contains_key("updated_at"), "Should contain updated_at at top-level");
        assert!(obj.contains_key("value"), "Should flatten value to top-level");
        assert!(obj.contains_key("active"), "Should flatten active to top-level");
        assert!(!obj.contains_key("data"), "Should not contain nested data key");
    } else {
        panic!("Expected Value::Object");
    }

    // Roundtrip deserialization
    let deserialized = GenericRecord::<MockFields>::from_value(value).expect("Should deserialize GenericRecord");
    assert_eq!(deserialized.id.table, "MockTable");
    assert_eq!(deserialized.id.key, "uuid-123");
    assert_eq!(deserialized.created_at, 12345);
    assert_eq!(deserialized.updated_at, 67890);
    assert_eq!(deserialized.data.value, "Hello");
    assert_eq!(deserialized.data.active, true);
}

