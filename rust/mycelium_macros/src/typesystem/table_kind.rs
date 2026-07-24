use proc_macro2::TokenStream;
use quote::quote;
use crate::typesystem::ast::{CategoryKind, EntityDef};

pub fn generate_table_kind(entities: &[EntityDef]) -> TokenStream {
    let mut variants = Vec::new();
    let mut table_name_arms = Vec::new();
    let mut category_arms = Vec::new();
    let mut from_table_name_arms = Vec::new();
    let mut try_from_u8_arms = Vec::new();

    for (idx, entity) in entities.iter().enumerate() {
        let name = &entity.name;
        let label = entity
            .table_attr
            .label
            .as_deref()
            .unwrap_or(&name.to_string())
            .to_string();

        let disc = idx as u8;
        let cat_variant = match entity.category {
            CategoryKind::Node => quote!(crate::domain::traits::TableCategory::Node),
            CategoryKind::Relation => quote!(crate::domain::traits::TableCategory::Relation),
            CategoryKind::Auxiliary => quote!(crate::domain::traits::TableCategory::Auxiliary),
        };

        variants.push(quote! { #name = #disc });
        table_name_arms.push(quote! { Self::#name => #label });
        category_arms.push(quote! { Self::#name => #cat_variant });
        from_table_name_arms.push(quote! { #label => Ok(Self::#name) });
        try_from_u8_arms.push(quote! { #disc => Ok(Self::#name) });
    }

    quote! {
        #[repr(u8)]
        #[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
        pub enum TableKind {
            #(#variants,)*
        }

        impl TableKind {
            #[inline]
            pub const fn table_name(self) -> &'static str {
                match self {
                    #(#table_name_arms,)*
                }
            }

            #[inline]
            pub const fn category(self) -> crate::domain::traits::TableCategory {
                match self {
                    #(#category_arms,)*
                }
            }

            pub fn from_table_name(table: &str) -> Result<Self, anyhow::Error> {
                match table {
                    #(#from_table_name_arms,)*
                    other => Err(anyhow::anyhow!("Unknown table name: {}", other)),
                }
            }
        }

        impl std::str::FromStr for TableKind {
            type Err = anyhow::Error;

            fn from_str(s: &str) -> Result<Self, Self::Err> {
                Self::from_table_name(s)
            }
        }

        impl TryFrom<u8> for TableKind {
            type Error = anyhow::Error;

            fn try_from(value: u8) -> Result<Self, Self::Error> {
                match value {
                    #(#try_from_u8_arms,)*
                    other => Err(anyhow::anyhow!("Invalid TableKind u8 discriminant: {}", other)),
                }
            }
        }
    }
}
