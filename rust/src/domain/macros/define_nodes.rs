#[macro_export]
macro_rules! define_nodes {
    (
        $(
            $struct_name:ident, $label:expr, [ $($fetch_field:expr),* ] {
                $(
                    $(#[surql_type = $type_override:expr])?
                    $(#[surql_default = $default_override:expr])?
                    $(#[surql_computed = $computed_override:expr])?
                    pub $field_name:ident : $field_type:ty
                ),* $(,)?
            };
        )*
    ) => {
        $(
            #[derive(Debug, Clone, surrealdb::types::SurrealValue, mycelium_macros::SurrealTable, mycelium_macros::NodeEntity)]
            pub struct $struct_name {
                pub id: $crate::domain::id::TypedRecordId,
                pub position: $crate::domain::base_models::Coordinates,
                pub layer: String,
                pub created_at: i64,
                pub updated_at: i64,
                $(
                    pub $field_name : $field_type,
                )*
            }

            impl $struct_name {
                pub const LABEL: &'static str = $label;
            }

            impl $crate::domain::base_models::IsTable for $struct_name {
                const LABEL: &'static str = $label;
                const FETCH_FIELDS: &'static [&'static str] = &[ $($fetch_field),* ];
                fn get_key(&self) -> &str {
                    ""
                }
            }

            impl $crate::domain::nodes::IsNode for $struct_name {
                fn id(&self) -> &$crate::domain::id::TypedRecordId {
                    &self.id
                }
                fn set_id(&mut self, id: $crate::domain::id::TypedRecordId) {
                    self.id = id;
                }
                fn position(&self) -> &$crate::domain::base_models::Coordinates {
                    &self.position
                }
                fn position_mut(&mut self) -> &mut $crate::domain::base_models::Coordinates {
                    &mut self.position
                }
                fn layer(&self) -> &str {
                    &self.layer
                }
                fn set_layer(&mut self, layer: String) {
                    self.layer = layer;
                }
                fn created_at(&self) -> i64 {
                    self.created_at
                }
                fn set_created_at(&mut self, val: i64) {
                    self.created_at = val;
                }
                fn updated_at(&self) -> i64 {
                    self.updated_at
                }
                fn set_updated_at(&mut self, val: i64) {
                    self.updated_at = val;
                }
                fn table_name(&self) -> &'static str {
                    Self::LABEL
                }
                fn serialize_node(self) -> surrealdb::types::Value {
                    use surrealdb::types::SurrealValue;
                    < Self as SurrealValue >::into_value(self)
                }
            }

            impl $crate::domain::nodes::SurqlSchema for $struct_name {
                fn generate_fields_schema(table: &str) -> Vec<String> {
                    let mut lines = Vec::new();
                    lines.push($crate::domain::schema::generate_created_at(table, true));
                    lines.push($crate::domain::schema::generate_updated_at(table));
                    lines.extend($crate::domain::nodes::generate_field_schema_lines(
                        table,
                        "position",
                        None,
                        None,
                        None,
                        < $crate::domain::base_models::Coordinates as $crate::domain::nodes::SurqlSchemaField >::field_type(),
                        < $crate::domain::base_models::Coordinates as $crate::domain::nodes::SurqlSchemaField >::sub_field_paths(),
                    ));
                    lines.extend($crate::domain::nodes::generate_field_schema_lines(
                        table,
                        "layer",
                        None,
                        None,
                        None,
                        < String as $crate::domain::nodes::SurqlSchemaField >::field_type(),
                        < String as $crate::domain::nodes::SurqlSchemaField >::sub_field_paths(),
                    ));
                    $(
                        let type_override: Option<&str> = None $(.or(Some($type_override)))?;
                        let default_override: Option<&str> = None $(.or(Some($default_override)))?;
                        let computed_override: Option<&str> = None $(.or(Some($computed_override)))?;

                        lines.extend($crate::domain::nodes::generate_field_schema_lines(
                            table,
                            stringify!($field_name),
                            type_override,
                            default_override,
                            computed_override,
                            < $field_type as $crate::domain::nodes::SurqlSchemaField >::field_type(),
                            < $field_type as $crate::domain::nodes::SurqlSchemaField >::sub_field_paths(),
                        ));
                    )*
                    lines
                }
            }
        )*
    };
}
