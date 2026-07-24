use proc_macro::TokenStream;
use quote::quote;
use syn::{parse_macro_input, Data, DeriveInput, Fields};

pub fn derive_surreal_table_impl(input: TokenStream) -> TokenStream {
    let input = parse_macro_input!(input as DeriveInput);
    let name = &input.ident;

    let Data::Struct(data_struct) = &input.data else {
        panic!("SurrealTable can only be derived on structs");
    };

    let mut key_field_ident = None;
    if let Fields::Named(named) = &data_struct.fields {
        for field in &named.named {
            if let Some(ident) = &field.ident {
                let fname = ident.to_string();
                if fname == "id" || fname == "key" {
                    key_field_ident = Some(ident.clone());
                    break;
                }
            }
        }
    }

    let key_access = if let Some(k_ident) = key_field_ident {
        quote! { &self.#k_ident.key }
    } else {
        quote! {
            static NIL_KEY: uuid::Uuid = uuid::Uuid::nil();
            &NIL_KEY
        }
    };

    let kind_ident = name;

    let expanded = quote! {
        impl crate::domain::traits::SurrealTable for #name {
            const KIND: crate::domain::traits::TableKind = crate::domain::traits::TableKind::#kind_ident;
            const FETCH_FIELDS: &'static [&'static str] = &[];

            fn get_key(&self) -> &uuid::Uuid {
                #key_access
            }
        }
    };

    TokenStream::from(expanded)
}

pub fn derive_node_entity_impl(input: TokenStream) -> TokenStream {
    let input = parse_macro_input!(input as DeriveInput);
    let name = &input.ident;
    let expanded = quote! {
        impl crate::domain::traits::NodeEntity for #name {}
    };
    TokenStream::from(expanded)
}

pub fn derive_relation_entity_impl(input: TokenStream) -> TokenStream {
    let input = parse_macro_input!(input as DeriveInput);
    let name = &input.ident;
    let expanded = quote! {
        impl crate::domain::traits::RelationEntity for #name {}
    };
    TokenStream::from(expanded)
}

pub fn derive_auxiliary_entity_impl(input: TokenStream) -> TokenStream {
    let input = parse_macro_input!(input as DeriveInput);
    let name = &input.ident;
    let expanded = quote! {
        impl crate::domain::traits::AuxiliaryEntity for #name {}
    };
    TokenStream::from(expanded)
}
