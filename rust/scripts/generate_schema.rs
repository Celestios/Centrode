use rust_lib_mycelium::persistence::schema_gen::generate_and_update_schema;
use std::path::Path;

fn main() {
    let schema_path = Path::new("src/persistence/schema.surql");
    assert!(
        schema_path.exists(),
        "schema.surql must exist at {:?}",
        schema_path.to_string_lossy()
    );

    generate_and_update_schema(schema_path).expect("Failed to update schema.surql");
    println!("schema.surql has been updated successfully via schema_gen sub-modules.");
}
