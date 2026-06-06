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
            #[derive(Debug, Clone, surrealdb::types::SurrealValue)]
            pub struct $struct_name {
                pub id: $crate::domain::base_models::RecordStrings,
                pub position: $crate::domain::base_models::Coordinates,
                pub layer: String,
                pub created_at: i64,
                pub updated_at: i64,
                $(
                    pub $field_name : $field_type,
                )*
            }

            impl $crate::domain::base_models::IsTable for $struct_name {
                const LABEL: &'static str = $label;
                const FETCH_FIELDS: &'static [&'static str] = &[ $($fetch_field),* ];
                fn get_key(&self) -> &str {
                    &self.id.key
                }
            }

            impl $crate::domain::nodes::IsNode for $struct_name {
                fn id(&self) -> &$crate::domain::base_models::RecordStrings {
                    &self.id
                }
                fn set_id(&mut self, id: $crate::domain::base_models::RecordStrings) {
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
                    < Self as surrealdb::types::SurrealValue >::into_value(self)
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

        #[derive(Debug, Clone, surrealdb::types::SurrealValue)]
        pub enum Nodes {
            $(
                $struct_name($struct_name),
            )*
        }

        impl $crate::domain::nodes::IsNode for Nodes {
            fn id(&self) -> &$crate::domain::base_models::RecordStrings {
                match self {
                    $(
                        Nodes::$struct_name(n) => n.id(),
                    )*
                }
            }
            fn set_id(&mut self, id: $crate::domain::base_models::RecordStrings) {
                match self {
                    $(
                        Nodes::$struct_name(n) => n.set_id(id),
                    )*
                }
            }
            fn position(&self) -> &$crate::domain::base_models::Coordinates {
                match self {
                    $(
                        Nodes::$struct_name(n) => n.position(),
                    )*
                }
            }
            fn position_mut(&mut self) -> &mut $crate::domain::base_models::Coordinates {
                match self {
                    $(
                        Nodes::$struct_name(n) => n.position_mut(),
                    )*
                }
            }
            fn layer(&self) -> &str {
                match self {
                    $(
                        Nodes::$struct_name(n) => n.layer(),
                    )*
                }
            }
            fn set_layer(&mut self, layer: String) {
                match self {
                    $(
                        Nodes::$struct_name(n) => n.set_layer(layer),
                    )*
                }
            }
            fn created_at(&self) -> i64 {
                match self {
                    $(
                        Nodes::$struct_name(n) => n.created_at(),
                    )*
                }
            }
            fn set_created_at(&mut self, val: i64) {
                match self {
                    $(
                        Nodes::$struct_name(n) => n.set_created_at(val),
                    )*
                }
            }
            fn updated_at(&self) -> i64 {
                match self {
                    $(
                        Nodes::$struct_name(n) => n.updated_at(),
                    )*
                }
            }
            fn set_updated_at(&mut self, val: i64) {
                match self {
                    $(
                        Nodes::$struct_name(n) => n.set_updated_at(val),
                    )*
                }
            }
            fn table_name(&self) -> &'static str {
                match self {
                    $(
                        Nodes::$struct_name(n) => n.table_name(),
                    )*
                }
            }
            fn serialize_node(self) -> surrealdb::types::Value {
                match self {
                    $(
                        Nodes::$struct_name(n) => n.serialize_node(),
                    )*
                }
            }
        }

        impl Nodes {
            pub const TABLES: &'static [&'static str] = &[
                $( $struct_name::LABEL ),*
            ];

            pub fn generate_all_fields_schemas() -> Vec<(&'static str, Vec<String>)> {
                vec![
                    $(
                        ($struct_name::LABEL, <$struct_name as $crate::domain::nodes::SurqlSchema>::generate_fields_schema($struct_name::LABEL)),
                    )*
                ]
            }

            pub fn fetch_fields_for_table(table: &str) -> &'static [&'static str] {
                match table {
                    $(
                        $struct_name::LABEL => $struct_name::FETCH_FIELDS,
                    )*
                    _ => &[],
                }
            }

            pub fn table_and_key(&self) -> (&'static str, &str) {
                match self {
                    $(
                        Nodes::$struct_name(n) => ($struct_name::LABEL, n.key()),
                    )*
                }
            }

            pub fn from_struct_value(table: &str, val: surrealdb::types::Value) -> Result<Self, surrealdb::types::Error> {
                match table {
                    $(
                        $struct_name::LABEL => Ok(Nodes::$struct_name(<$struct_name as surrealdb::types::SurrealValue>::from_value(val)?)),
                    )*
                    _ => Err(surrealdb::types::Error::thrown(format!("Unknown node table: {}", table))),
                }
            }
        }
    };
}
