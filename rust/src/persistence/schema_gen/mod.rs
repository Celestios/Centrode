pub mod auxiliary;
pub mod nodes;
pub mod relations;
pub mod writer;

use std::path::Path;

pub fn generate_and_update_schema(schema_path: &Path) -> std::io::Result<()> {
    let node_schemas = nodes::generate_node_schemas();
    let mut generated_block = String::new();
    let mut node_names = Vec::new();

    for (name, lines) in &node_schemas {
        node_names.push(*name);
        generated_block.push_str(&auxiliary::format_schema_block(name, lines));
    }

    let (in_line, out_line) = relations::generate_relation_record_constraints(&node_names);
    writer::update_schema_file(schema_path, &generated_block, &in_line, &out_line)
}
