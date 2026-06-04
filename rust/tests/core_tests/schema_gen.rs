use mycelium_core::domain::nodes::{
    INode, TaskNode, InterNode, CommentNode, DrawingNode, ShapeNode, FrameNode, MediaNode, SurqlSchema
};
use std::fs;
use std::path::Path;

#[test]
fn test_generate_schema_file() {
    let mut generated_schema = String::new();

    let node_schemas = vec![
        ("INode", INode::generate_fields_schema("INode")),
        ("TaskNode", TaskNode::generate_fields_schema("TaskNode")),
        ("InterNode", InterNode::generate_fields_schema("InterNode")),
        ("CommentNode", CommentNode::generate_fields_schema("CommentNode")),
        ("DrawingNode", DrawingNode::generate_fields_schema("DrawingNode")),
        ("ShapeNode", ShapeNode::generate_fields_schema("ShapeNode")),
        ("FrameNode", FrameNode::generate_fields_schema("FrameNode")),
        ("MediaNode", MediaNode::generate_fields_schema("MediaNode")),
    ];

    for (name, lines) in node_schemas {
        generated_schema.push_str(&format!("-- ---------------------------------------------------------------------------\n"));
        generated_schema.push_str(&format!("-- Fields for `{}`\n", name));
        generated_schema.push_str(&format!("-- ---------------------------------------------------------------------------\n"));
        for line in lines {
            generated_schema.push_str(&line);
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

    fs::write(schema_path, new_content).expect("Failed to write updated schema.surql");
    println!("schema.surql has been updated successfully.");
}
