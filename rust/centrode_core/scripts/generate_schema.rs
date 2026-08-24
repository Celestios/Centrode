use centrode_daemon::schema_gen::generate_and_update_schema;
use std::path::Path;

fn main() {
    let schema_path = Path::new("../centrode_daemon/src/map_schema.surql");
    assert!(
        schema_path.exists(),
        "map_schema.surql must exist at {:?}",
        schema_path.to_string_lossy()
    );

    generate_and_update_schema(schema_path).expect("Failed to update map_schema.surql");
    println!("map_schema.surql has been updated successfully via schema_gen sub-modules.");
}
