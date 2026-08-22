pub trait SurqlSchema {
    fn generate_fields_schema(table: &str) -> Vec<String>;
}

pub trait SurqlSchemaField {
    fn field_type() -> String;
    fn sub_field_paths() -> Vec<(String, String)>;
}

pub fn generate_field_schema_lines(
    table: &str,
    field_name: &str,
    type_override: Option<&str>,
    default_override: Option<&str>,
    field_type: String,
    sub_field_paths: Vec<(String, String)>,
) -> Vec<String> {
    let mut lines = Vec::new();

    let ty = type_override.map(|s| s.to_string()).unwrap_or(field_type);
    let default_str = default_override
        .map(|d| format!(" DEFAULT {}", d))
        .unwrap_or_default();
    lines.push(format!(
        "DEFINE FIELD OVERWRITE {} ON TABLE {} TYPE {}{};",
        field_name, table, ty, default_str
    ));

    for (sub_path, sub_type) in sub_field_paths {
        lines.push(format!(
            "DEFINE FIELD OVERWRITE {}.{} ON TABLE {} TYPE {};",
            field_name, sub_path, table, sub_type
        ));
    }

    lines
}

pub fn generate_created_at(table: &str, readonly: bool) -> String {
    if readonly {
        format!(
            "DEFINE FIELD OVERWRITE created_at ON TABLE {} TYPE int DEFAULT time::millis(time::now()) READONLY;",
            table
        )
    } else {
        format!(
            "DEFINE FIELD OVERWRITE created_at ON TABLE {} TYPE int DEFAULT time::millis(time::now());",
            table
        )
    }
}

pub fn generate_updated_at(table: &str) -> String {
    format!(
        "DEFINE FIELD OVERWRITE updated_at ON TABLE {} TYPE int VALUE $value OR time::millis(time::now());",
        table
    )
}

impl SurqlSchemaField for String {
    fn field_type() -> String { "string".to_string() }
    fn sub_field_paths() -> Vec<(String, String)> { vec![] }
}

impl SurqlSchemaField for i64 {
    fn field_type() -> String { "int".to_string() }
    fn sub_field_paths() -> Vec<(String, String)> { vec![] }
}

impl SurqlSchemaField for i32 {
    fn field_type() -> String { "int".to_string() }
    fn sub_field_paths() -> Vec<(String, String)> { vec![] }
}

impl SurqlSchemaField for u8 {
    fn field_type() -> String { "int".to_string() }
    fn sub_field_paths() -> Vec<(String, String)> { vec![] }
}

impl SurqlSchemaField for u32 {
    fn field_type() -> String { "int".to_string() }
    fn sub_field_paths() -> Vec<(String, String)> { vec![] }
}

impl SurqlSchemaField for bool {
    fn field_type() -> String { "bool".to_string() }
    fn sub_field_paths() -> Vec<(String, String)> { vec![] }
}

impl<T: SurqlSchemaField> SurqlSchemaField for Option<T> {
    fn field_type() -> String {
        format!("option<{}>", T::field_type())
    }
    fn sub_field_paths() -> Vec<(String, String)> {
        T::sub_field_paths()
    }
}

impl<T: SurqlSchemaField> SurqlSchemaField for Vec<T> {
    fn field_type() -> String {
        "array".to_string()
    }
    fn sub_field_paths() -> Vec<(String, String)> {
        let sub = T::sub_field_paths();
        if sub.is_empty() {
            vec![]
        } else {
            let mut paths = vec![("*".to_string(), T::field_type())];
            for (sub_path, sub_type) in sub {
                paths.push((format!("*.{}", sub_path), sub_type));
            }
            paths
        }
    }
}

impl SurqlSchemaField for f64 {
    fn field_type() -> String { "float".to_string() }
    fn sub_field_paths() -> Vec<(String, String)> { vec![] }
}

impl SurqlSchemaField for crate::id::TypedRecordId {
    fn field_type() -> String { "record".to_string() }
    fn sub_field_paths() -> Vec<(String, String)> { vec![] }
}

impl SurqlSchemaField for f32 {
    fn field_type() -> String { "float".to_string() }
    fn sub_field_paths() -> Vec<(String, String)> { vec![] }
}
