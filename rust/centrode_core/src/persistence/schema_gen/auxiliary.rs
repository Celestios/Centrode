pub fn format_schema_block(name: &str, field_lines: &[String]) -> String {
    let mut block = String::new();
    block.push_str("-- ---------------------------------------------------------------------------\n");
    block.push_str(&format!("-- Fields for `{}`\n", name));
    block.push_str("-- ---------------------------------------------------------------------------\n");
    for line in field_lines {
        block.push_str(line);
        block.push_str("\n");
    }
    block.push_str("\n");
    block
}
