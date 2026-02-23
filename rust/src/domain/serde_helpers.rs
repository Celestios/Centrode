// src/domain/serde_helpers.rs
use serde::{Deserialize, Deserializer, Serializer};
use surrealdb::sql::Thing;

/// Serde module to handle Option<Thing> <-> Option<String>
pub mod option_thing_string {
    use super::*;

    pub fn serialize<S>(value: &Option<String>, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        match value {
            Some(s) => {
                // Convert "table:id" string back to Thing for the DB
                let (table, id) = s.split_once(':')
                    .ok_or_else(|| serde::ser::Error::custom(format!("Invalid Record ID format: {}", s)))?;
                
                let thing = Thing::from((table, id));
                serializer.serialize_some(&thing)
            },
            None => serializer.serialize_none(),
        }
    }

    pub fn deserialize<'de, D>(deserializer: D) -> Result<Option<String>, D::Error>
    where
        D: Deserializer<'de>,
    {
        // Receive Thing from DB, convert to "table:id" string
        let opt: Option<Thing> = Option::deserialize(deserializer)?;
        Ok(opt.map(|t| t.to_string()))
    }
}