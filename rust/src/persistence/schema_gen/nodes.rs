use crate::domain::nodes::Nodes;

pub fn generate_node_schemas() -> Vec<(&'static str, Vec<String>)> {
    Nodes::generate_all_fields_schemas()
}
