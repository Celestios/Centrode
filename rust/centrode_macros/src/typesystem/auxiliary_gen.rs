use proc_macro2::TokenStream;
use quote::quote;
use crate::typesystem::ast::{CategoryKind, EntityDef};

pub fn generate_auxiliary(entities: &[EntityDef]) -> TokenStream {
    let aux_entities: Vec<&EntityDef> = entities
        .iter()
        .filter(|e| e.category == CategoryKind::Auxiliary)
        .collect();

    let mut struct_tokens = Vec::new();
    let mut enum_variants = Vec::new();

    for entity in &aux_entities {
        let name = &entity.name;
        let vis = &entity.vis;
        let attrs = &entity.attrs;
        let label = entity
            .table_attr
            .label
            .as_deref()
            .unwrap_or(&name.to_string())
            .to_string();

        let has_key = entity.fields.iter().any(|f| f.ident.as_ref().map_or(false, |i| i == "key"));
        let has_id = entity.fields.iter().any(|f| f.ident.as_ref().map_or(false, |i| i == "id"));

        let mut injected_fields = Vec::new();
        if !has_key && !has_id && !entity.table_attr.no_key {
            injected_fields.push(quote! { pub key: crate::domain::id::TypedRecordId });
        }

        let user_fields = &entity.fields;

        struct_tokens.push(quote! {
            #(#attrs)*
            #[derive(Debug, Clone, surrealdb::types::SurrealValue, centrode_macros::SurrealTable, centrode_macros::AuxiliaryEntity)]
            #vis struct #name {
                #(#injected_fields,)*
                #(#user_fields,)*
            }

            impl #name {
                pub const LABEL: &'static str = #label;
            }
        });

        enum_variants.push(quote! { #name(#name) });
    }

    quote! {
        #(#struct_tokens)*

        #[derive(Debug, Clone, surrealdb::types::SurrealValue)]
        pub enum Auxiliary {
            #(#enum_variants,)*
        }
    }
}
