pub fn generate_relation_record_constraints(node_table_names: &[&str]) -> (String, String) {
    let union_types = node_table_names.join(" | ");
    let in_line = format!("DEFINE FIELD OVERWRITE in ON TABLE IRelation TYPE record<{}>;", union_types);
    let out_line = format!("DEFINE FIELD OVERWRITE out ON TABLE IRelation TYPE record<{}>;", union_types);
    (in_line, out_line)
}
