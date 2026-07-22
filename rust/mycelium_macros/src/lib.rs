use proc_macro::TokenStream;
use quote::quote;
use syn::{parse_macro_input, Data, DeriveInput, Fields};

fn to_snake_case(s: &str) -> String {
    let mut acc = String::new();
    let mut prev_is_uppercase = false;

    for (i, ch) in s.chars().enumerate() {
        if ch.is_uppercase() {
            if i > 0 && !prev_is_uppercase {
                acc.push('_');
            }
            acc.push(ch.to_ascii_lowercase());
            prev_is_uppercase = true;
        } else {
            acc.push(ch);
            prev_is_uppercase = false;
        }
    }
    acc
}

#[proc_macro_derive(SurrealDbEnum, attributes(surreal_enum))]
pub fn derive_surreal_db_enum(input: TokenStream) -> TokenStream {
    let input = parse_macro_input!(input as DeriveInput);
    let name = &input.ident;

    let Data::Enum(data_enum) = &input.data else {
        panic!("SurrealDbEnum can only be derived on enums");
    };

    let mut to_str_arms = Vec::new();
    let mut from_bytes_arms = Vec::new();

    for variant in &data_enum.variants {
        let v_ident = &variant.ident;
        let v_str = to_snake_case(&v_ident.to_string());
        let v_bytes = syn::LitByteStr::new(v_str.as_bytes(), v_ident.span());

        to_str_arms.push(quote! {
            Self::#v_ident => #v_str
        });

        from_bytes_arms.push(quote! {
            #v_bytes => Ok(Self::#v_ident)
        });
    }

    let expanded = quote! {
        impl crate::domain::traits::SurrealDbEnum for #name {
            #[inline]
            fn to_surreal_str(&self) -> &'static str {
                match self {
                    #(#to_str_arms,)*
                }
            }

            #[inline]
            fn from_surreal_bytes(bytes: &[u8]) -> Result<Self, anyhow::Error> {
                match bytes {
                    #(#from_bytes_arms,)*
                    _ => Err(anyhow::anyhow!("Unknown {} enum string: {:?}", stringify!(#name), std::str::from_utf8(bytes))),
                }
            }
        }

        impl surrealdb::types::SurrealValue for #name {
            fn kind_of() -> surrealdb::types::Kind {
                surrealdb::types::Kind::String
            }

            fn into_value(self) -> surrealdb::types::Value {
                surrealdb::types::Value::String(crate::domain::traits::SurrealDbEnum::to_surreal_str(&self).to_string())
            }

            fn from_value(value: surrealdb::types::Value) -> Result<Self, surrealdb::types::Error> {
                match value {
                    surrealdb::types::Value::String(s) => {
                        crate::domain::traits::SurrealDbEnum::from_surreal_bytes(s.as_bytes())
                            .map_err(|e| surrealdb::types::Error::thrown(e.to_string()))
                    }
                    unsupported => Err(surrealdb::types::Error::thrown(format!("Expected String for {}, found: {:?}", stringify!(#name), unsupported))),
                }
            }
        }

        impl std::fmt::Display for #name {
            fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
                write!(f, "{}", crate::domain::traits::SurrealDbEnum::to_surreal_str(self))
            }
        }

        impl std::str::FromStr for #name {
            type Err = anyhow::Error;
            fn from_str(s: &str) -> Result<Self, Self::Err> {
                crate::domain::traits::SurrealDbEnum::from_surreal_bytes(s.as_bytes())
            }
        }
    };

    TokenStream::from(expanded)
}

#[proc_macro_derive(SurrealTable, attributes(surreal_table))]
pub fn derive_surreal_table(input: TokenStream) -> TokenStream {
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
        quote! { panic!("Struct {} does not have id or key field", stringify!(#name)) }
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

#[proc_macro_derive(NodeEntity)]
pub fn derive_node_entity(input: TokenStream) -> TokenStream {
    let input = parse_macro_input!(input as DeriveInput);
    let name = &input.ident;
    let expanded = quote! {
        impl crate::domain::traits::NodeEntity for #name {}
    };
    TokenStream::from(expanded)
}

#[proc_macro_derive(RelationEntity)]
pub fn derive_relation_entity(input: TokenStream) -> TokenStream {
    let input = parse_macro_input!(input as DeriveInput);
    let name = &input.ident;
    let expanded = quote! {
        impl crate::domain::traits::RelationEntity for #name {}
    };
    TokenStream::from(expanded)
}

#[proc_macro_derive(AuxiliaryEntity)]
pub fn derive_auxiliary_entity(input: TokenStream) -> TokenStream {
    let input = parse_macro_input!(input as DeriveInput);
    let name = &input.ident;
    let expanded = quote! {
        impl crate::domain::traits::AuxiliaryEntity for #name {}
    };
    TokenStream::from(expanded)
}
