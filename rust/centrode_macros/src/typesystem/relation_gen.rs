use proc_macro2::TokenStream;
use quote::quote;
use crate::typesystem::ast::{CategoryKind, EntityDef};

pub fn generate_relations(entities: &[EntityDef]) -> TokenStream {
    let rel_entities: Vec<&EntityDef> = entities
        .iter()
        .filter(|e| e.category == CategoryKind::Relation)
        .collect();

    let mut struct_tokens = Vec::new();
    let mut enum_variants = Vec::new();

    for entity in &rel_entities {
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
        let has_in = entity.fields.iter().any(|f| f.ident.as_ref().map_or(false, |i| i == "in_"));
        let has_out = entity.fields.iter().any(|f| f.ident.as_ref().map_or(false, |i| i == "out"));

        let mut injected_fields = Vec::new();
        if !has_key {
            injected_fields.push(quote! { pub key: crate::domain::id::TypedRecordId });
        }
        if !has_in {
            injected_fields.push(quote! { pub in_: crate::domain::id::TypedRecordId });
        }
        if !has_out {
            injected_fields.push(quote! { pub out: crate::domain::id::TypedRecordId });
        }

        let user_fields = &entity.fields;

        struct_tokens.push(quote! {
            #(#attrs)*
            #[derive(Debug, Clone, centrode_macros::SurrealTable, centrode_macros::RelationEntity)]
            #vis struct #name {
                #(#injected_fields,)*
                #(#user_fields,)*
            }

            impl #name {
                pub const LABEL: &'static str = #label;
            }

            impl surrealdb::types::SurrealValue for #name {
                fn kind_of() -> surrealdb::types::Kind {
                    surrealdb::types::Kind::Object
                }

                fn from_value(value: surrealdb::types::Value) -> Result<Self, surrealdb::types::Error> {
                    use surrealdb::types::SurrealValue;
                    let surrealdb::types::Value::Object(mut fields_map) = value else {
                        return Err(surrealdb::types::Error::thrown(
                            format!("Fields must be an object for {}", stringify!(#name)),
                        ));
                    };

                    let id_val = fields_map.remove("id").ok_or_else(|| {
                        surrealdb::types::Error::thrown(format!("Missing 'id' field in {}", stringify!(#name)))
                    })?;
                    let in_val = fields_map.remove("in").ok_or_else(|| {
                        surrealdb::types::Error::thrown(format!("Missing 'in' field in {}", stringify!(#name)))
                    })?;
                    let out_val = fields_map.remove("out").ok_or_else(|| {
                        surrealdb::types::Error::thrown(format!("Missing 'out' field in {}", stringify!(#name)))
                    })?;

                    let key = crate::domain::id::TypedRecordId::from_value(id_val)?;
                    let in_ = crate::domain::id::TypedRecordId::from_value(in_val)?;
                    let out = crate::domain::id::TypedRecordId::from_value(out_val)?;

                    let fields_obj = surrealdb::types::Value::Object(fields_map);
                    let fields = crate::domain::relations::IRelationFields::from_value(fields_obj)?;

                    Ok(#name {
                        key,
                        in_,
                        out,
                        fields,
                    })
                }

                fn into_value(self) -> surrealdb::types::Value {
                    use surrealdb::types::SurrealValue;
                    let val = self.fields.into_value();
                    match val {
                        surrealdb::types::Value::Object(mut obj) => {
                            obj.insert("id".to_string(), self.key.into_value());
                            obj.insert("in".to_string(), self.in_.into_value());
                            obj.insert("out".to_string(), self.out.into_value());
                            surrealdb::types::Value::Object(obj)
                        }
                        other => {
                            let mut obj = std::collections::BTreeMap::new();
                            obj.insert("id".to_string(), self.key.into_value());
                            obj.insert("in".to_string(), self.in_.into_value());
                            obj.insert("out".to_string(), self.out.into_value());
                            surrealdb::types::Value::Object(obj.into())
                        }
                    }
                }
            }
        });

        enum_variants.push(quote! { #name(#name) });
    }

    quote! {
        #(#struct_tokens)*

        #[derive(Debug, Clone, surrealdb::types::SurrealValue)]
        pub enum Relations {
            #(#enum_variants,)*
        }
    }
}
