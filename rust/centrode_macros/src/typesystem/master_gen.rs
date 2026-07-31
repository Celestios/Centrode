use proc_macro2::TokenStream;
use quote::quote;

pub fn generate_master_entity() -> TokenStream {
    quote! {
        #[derive(Debug, Clone, surrealdb::types::SurrealValue)]
        pub enum DomainEntity {
            Node(Nodes),
            Relation(Relations),
            Auxiliary(Auxiliary),
        }

        impl From<Nodes> for DomainEntity {
            fn from(val: Nodes) -> Self {
                DomainEntity::Node(val)
            }
        }

        impl From<Relations> for DomainEntity {
            fn from(val: Relations) -> Self {
                DomainEntity::Relation(val)
            }
        }

        impl From<Auxiliary> for DomainEntity {
            fn from(val: Auxiliary) -> Self {
                DomainEntity::Auxiliary(val)
            }
        }
    }
}
