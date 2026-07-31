use proc_macro::TokenStream;
use quote::quote;
use syn::{parse_macro_input, Data, DeriveInput, Fields};

pub fn derive_surql_schema_field_impl(input: TokenStream) -> TokenStream {
    let input = parse_macro_input!(input as DeriveInput);
    let name = &input.ident;

    let Data::Struct(data_struct) = &input.data else {
        panic!("SurqlSchemaField can only be derived on structs");
    };

    let mut field_tuples = Vec::new();
    if let Fields::Named(named) = &data_struct.fields {
        for field in &named.named {
            if let Some(ident) = &field.ident {
                let fname_str = ident.to_string();
                let ftype = &field.ty;
                field_tuples.push(quote! {
                    (#fname_str.to_string(), <#ftype as crate::domain::schema::SurqlSchemaField>::field_type())
                });
            }
        }
    }

    let expanded = quote! {
        impl crate::domain::schema::SurqlSchemaField for #name {
            fn field_type() -> String {
                "object".to_string()
            }
            fn sub_field_paths() -> Vec<(String, String)> {
                vec![
                    #(#field_tuples),*
                ]
            }
        }
    };

    TokenStream::from(expanded)
}
