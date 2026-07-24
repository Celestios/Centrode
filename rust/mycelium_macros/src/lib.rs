//! Domain Code Generation & Persistence Derive Suite
//! ================================================
//!
//! Provides procedural macros for domain type system expansion, database serialization,
//! and schema reflection.
//!
//! Macro Contracts:
//! -----------------
//! - `define_domain_types!`: Parses declarative AST specifications into concrete domain struct types, 
//!   category sum-type union enums, and persistence contract traits (`IsNode`, `DomainEntity`, `SurqlSchema`).
//! - `#[derive(SurrealDbEnum)]`: Derives bidirectional string and integer conversions for domain enums.
//! - `#[derive(SurrealTable)]`, `#[derive(NodeEntity)]`, `#[derive(RelationEntity)]`, `#[derive(AuxiliaryEntity)]`: 
//!   Derives database table mappings, key accessors, and SurrealDB record identifier implementations.
//! - `#[derive(SurqlSchemaField)]`: Derives schema generator field reflection metadata.

use proc_macro::TokenStream;

mod surreal_enum;
mod surreal_table;
mod surql_schema_field;
mod typesystem;

/// Expands domain type declarations into struct types, `Nodes`/`Relations` sum-type enums, and domain traits.
#[proc_macro]
pub fn define_domain_types(input: TokenStream) -> TokenStream {
    typesystem::define_domain_types_impl(input)
}

#[proc_macro_derive(SurrealDbEnum, attributes(surreal_enum))]
pub fn derive_surreal_db_enum(input: TokenStream) -> TokenStream {
    surreal_enum::derive_surreal_db_enum_impl(input)
}

#[proc_macro_derive(SurrealTable, attributes(surreal_table))]
pub fn derive_surreal_table(input: TokenStream) -> TokenStream {
    surreal_table::derive_surreal_table_impl(input)
}

#[proc_macro_derive(NodeEntity)]
pub fn derive_node_entity(input: TokenStream) -> TokenStream {
    surreal_table::derive_node_entity_impl(input)
}

#[proc_macro_derive(RelationEntity)]
pub fn derive_relation_entity(input: TokenStream) -> TokenStream {
    surreal_table::derive_relation_entity_impl(input)
}

#[proc_macro_derive(AuxiliaryEntity)]
pub fn derive_auxiliary_entity(input: TokenStream) -> TokenStream {
    surreal_table::derive_auxiliary_entity_impl(input)
}

#[proc_macro_derive(SurqlSchemaField)]
pub fn derive_surql_schema_field(input: TokenStream) -> TokenStream {
    surql_schema_field::derive_surql_schema_field_impl(input)
}

