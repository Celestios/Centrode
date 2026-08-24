use std::fs;
use std::path::Path;

pub fn update_schema_file(schema_path: &Path, generated_block: &str, in_constraint: &str, out_constraint: &str) -> std::io::Result<()> {
    let content = fs::read_to_string(schema_path)?;

    let begin_marker = "-- BEGIN GENERATED NODE FIELDS";
    let end_marker = "-- END GENERATED NODE FIELDS";

    let start_idx = content
        .find(begin_marker)
        .expect("Could not find BEGIN GENERATED NODE FIELDS marker in map_schema.surql");
    let end_idx = content
        .find(end_marker)
        .expect("Could not find END GENERATED NODE FIELDS marker in map_schema.surql");

    let mut new_content = String::new();
    new_content.push_str(&content[..start_idx]);
    new_content.push_str(begin_marker);
    new_content.push_str("\n\n");
    new_content.push_str(generated_block);
    new_content.push_str(end_marker);
    new_content.push_str(&content[end_idx + end_marker.len()..]);

    let in_prefix = "DEFINE FIELD OVERWRITE in ON TABLE IRelation TYPE record<";
    let out_prefix = "DEFINE FIELD OVERWRITE out ON TABLE IRelation TYPE record<";

    let mut lines = Vec::new();
    for line in new_content.lines() {
        let trimmed = line.trim();
        if trimmed.starts_with(in_prefix) {
            lines.push(in_constraint.to_string());
        } else if trimmed.starts_with(out_prefix) {
            lines.push(out_constraint.to_string());
        } else {
            lines.push(line.to_string());
        }
    }
    let final_content = lines.join("\n") + "\n";
    fs::write(schema_path, final_content)
}
