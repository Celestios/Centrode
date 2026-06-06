use rust_lib_mycelium::domain::nodes::Nodes;
use std::fs;
use std::path::Path;

fn main() {
    let mut generated_schema = String::new();

    let node_schemas = Nodes::generate_all_fields_schemas();

    for (name, lines) in &node_schemas {
        generated_schema.push_str(&format!("-- ---------------------------------------------------------------------------\n"));
        generated_schema.push_str(&format!("-- Fields for `{}`\n", name));
        generated_schema.push_str(&format!("-- ---------------------------------------------------------------------------\n"));
        for line in lines {
            generated_schema.push_str(line);
            generated_schema.push_str("\n");
        }
        generated_schema.push_str("\n");
    }

    // Locate schema.surql relative to the crate root
    let schema_path = Path::new("src/persistence/schema.surql");
    assert!(schema_path.exists(), "schema.surql must exist at {:?}", schema_path.to_string_lossy());

    let content = fs::read_to_string(schema_path).expect("Failed to read schema.surql");

    let begin_marker = "-- BEGIN GENERATED NODE FIELDS";
    let end_marker = "-- END GENERATED NODE FIELDS";

    let start_idx = content.find(begin_marker).expect("Could not find BEGIN GENERATED NODE FIELDS marker in schema.surql");
    let end_idx = content.find(end_marker).expect("Could not find END GENERATED NODE FIELDS marker in schema.surql");

    let mut new_content = String::new();
    new_content.push_str(&content[..start_idx]);
    new_content.push_str(begin_marker);
    new_content.push_str("\n\n");
    new_content.push_str(&generated_schema);
    new_content.push_str(end_marker);
    new_content.push_str(&content[end_idx + end_marker.len()..]);

    // Dynamically replace IRelation 'in' and 'out' record constraints
    let node_names: Vec<&str> = node_schemas.iter().map(|(name, _)| *name).collect();
    let union_types = node_names.join(" | ");
    let in_prefix = "DEFINE FIELD OVERWRITE in ON TABLE IRelation TYPE record<";
    let out_prefix = "DEFINE FIELD OVERWRITE out ON TABLE IRelation TYPE record<";

    let mut lines = Vec::new();
    for line in new_content.lines() {
        let trimmed = line.trim();
        if trimmed.starts_with(in_prefix) {
            lines.push(format!("{} {}>;", in_prefix, union_types));
        } else if trimmed.starts_with(out_prefix) {
            lines.push(format!("{} {}>;", out_prefix, union_types));
        } else {
            lines.push(line.to_string());
        }
    }
    let final_content = lines.join("\n") + "\n";

    fs::write(schema_path, final_content).expect("Failed to write updated schema.surql");
    println!("schema.surql has been updated successfully.");
}
