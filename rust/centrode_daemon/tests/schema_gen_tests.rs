use std::fs;
use tempfile::NamedTempFile;
use surrealdb::Surreal;
use surrealdb::engine::local::Mem;
use centrode_daemon::schema_gen::generate_and_update_schema;

#[tokio::test]
async fn test_schema_gen_and_execution() {
    let base_template = r#"
DEFINE TABLE OVERWRITE INode SCHEMAFULL;
DEFINE TABLE OVERWRITE TaskNode SCHEMAFULL;
DEFINE TABLE OVERWRITE IRelation TYPE RELATION SCHEMAFULL;

-- BEGIN GENERATED NODE FIELDS
-- END GENERATED NODE FIELDS

DEFINE FIELD OVERWRITE in ON TABLE IRelation TYPE record<INode>;
DEFINE FIELD OVERWRITE out ON TABLE IRelation TYPE record<INode>;
"#;
    let temp_file = NamedTempFile::new().expect("Failed to create tempfile");
    fs::write(temp_file.path(), base_template).expect("Failed to write base template");

    generate_and_update_schema(temp_file.path()).expect("Failed to generate and update schema");

    let content = fs::read_to_string(temp_file.path()).expect("Failed to read updated schema");
    assert!(content.contains("DEFINE FIELD OVERWRITE created_at ON TABLE INode"));
    assert!(content.contains("DEFINE FIELD OVERWRITE created_at ON TABLE TaskNode"));
    assert!(content.contains("DEFINE FIELD OVERWRITE in ON TABLE IRelation TYPE record<"));

    // Verify SurrealDB accepts the generated schema directly
    let db = Surreal::new::<Mem>(()).await.expect("Failed to init mem db");
    db.use_ns("test").use_db("test").await.expect("Failed to use db");
    db.query(content).await.expect("SurrealDB failed to execute generated schema");
}
