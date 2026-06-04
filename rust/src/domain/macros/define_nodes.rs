#[macro_export]
macro_rules! define_nodes {
    (
        $(
            $struct_name:ident, $fields_struct:ident, $label:expr, [ $($fetch_field:expr),* ];
        )*
    ) => {
        $(
            #[derive(Debug, Clone, surrealdb::types::SurrealValue)]
            pub struct $struct_name {
                pub key: String,
                pub fields: $fields_struct,
            }

            impl $crate::domain::base_models::IsTable for $struct_name {
                const LABEL: &'static str = $label;
                const FETCH_FIELDS: &'static [&'static str] = &[ $($fetch_field),* ];
                fn get_key(&self) -> &str {
                    &self.key
                }
            }

            impl From<(String, $fields_struct)> for $struct_name {
                fn from((key, fields): (String, $fields_struct)) -> Self {
                    Self { key, fields }
                }
            }

            impl $crate::domain::nodes::IsNode for $struct_name {
                fn key(&self) -> &str {
                    &self.key
                }
                fn set_key(&mut self, key: String) {
                    self.key = key;
                }
                fn position(&self) -> &$crate::domain::base_models::Coordinates {
                    &self.fields.position
                }
                fn position_mut(&mut self) -> &mut $crate::domain::base_models::Coordinates {
                    &mut self.fields.position
                }
                fn layer(&self) -> &str {
                    &self.fields.layer
                }
                fn set_layer(&mut self, layer: String) {
                    self.fields.layer = layer;
                }
                fn created_at(&self) -> i64 {
                    self.fields.created_at
                }
                fn set_created_at(&mut self, val: i64) {
                    self.fields.created_at = val;
                }
                fn updated_at(&self) -> i64 {
                    self.fields.updated_at
                }
                fn set_updated_at(&mut self, val: i64) {
                    self.fields.updated_at = val;
                }
                fn table_name(&self) -> &'static str {
                    Self::LABEL
                }
                fn fields_value(&self) -> surrealdb::types::Value {
                    < $fields_struct as surrealdb::types::SurrealValue >::into_value(self.fields.clone())
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
            fn key(&self) -> &str {
                match self {
                    $(
                        Nodes::$struct_name(n) => n.key(),
                    )*
                }
            }
            fn set_key(&mut self, key: String) {
                match self {
                    $(
                        Nodes::$struct_name(n) => n.set_key(key),
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
            fn fields_value(&self) -> surrealdb::types::Value {
                match self {
                    $(
                        Nodes::$struct_name(n) => n.fields_value(),
                    )*
                }
            }
        }

        impl Nodes {
            pub const TABLES: &'static [&'static str] = &[
                $( $struct_name::LABEL ),*
            ];

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
                        Nodes::$struct_name(n) => ($struct_name::LABEL, &n.key),
                    )*
                }
            }

            pub fn fields_into_value(self) -> surrealdb::types::Value {
                match self {
                    $(
                        Nodes::$struct_name(n) => n.fields.into_value(),
                    )*
                }
            }

            pub fn into_value(self) -> surrealdb::types::Value {
                match self {
                    $(
                        Nodes::$struct_name(n) => n.into_value(),
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

            pub fn from_table_and_value(table: &str, key: String, val: surrealdb::types::Value) -> Result<Self, surrealdb::types::Error> {
                match table {
                    $(
                        $struct_name::LABEL => Ok(Nodes::$struct_name($struct_name {
                            key,
                            fields: <$fields_struct as surrealdb::types::SurrealValue>::from_value(val)?,
                        })),
                    )*
                    _ => Err(surrealdb::types::Error::thrown(format!("Unknown node table: {}", table))),
                }
            }
        }
    };
}
