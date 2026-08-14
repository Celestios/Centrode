use proc_macro2::TokenStream;
use quote::quote;

use crate::typesystem::ast::{CategoryKind, EntityDef};

pub fn generate_nodes(entities: &[EntityDef]) -> TokenStream {
    let node_entities: Vec<&EntityDef> = entities
        .iter()
        .filter(|e| e.category == CategoryKind::Node)
        .collect();

    let mut struct_tokens = Vec::new();
    let mut enum_variants = Vec::new();
    let mut tables_slice = Vec::new();
    let mut schema_arms = Vec::new();
    let mut from_struct_arms = Vec::new();

    // IsNode match arms
    let mut id_arms = Vec::new();
    let mut set_id_arms = Vec::new();
    let mut parent_container_id_arms = Vec::new();
    let mut set_parent_container_id_arms = Vec::new();
    let mut pos_arms = Vec::new();
    let mut pos_mut_arms = Vec::new();
    let mut layer_arms = Vec::new();
    let mut set_layer_arms = Vec::new();
    let mut created_at_arms = Vec::new();
    let mut set_created_at_arms = Vec::new();
    let mut updated_at_arms = Vec::new();
    let mut set_updated_at_arms = Vec::new();
    let mut table_name_arms = Vec::new();
    let mut serialize_node_arms = Vec::new();

    for entity in &node_entities {
        let name = &entity.name;
        let vis = &entity.vis;
        let attrs = &entity.attrs;
        let label = entity
            .table_attr
            .label
            .as_deref()
            .unwrap_or(&name.to_string())
            .to_string();

        let has_id = entity
            .fields
            .iter()
            .any(|f| f.ident.as_ref().map_or(false, |i| i == "id"));
        let has_parent_container_id = entity
            .fields
            .iter()
            .any(|f| f.ident.as_ref().map_or(false, |i| i == "parent_container_id"));
        let has_pos = entity
            .fields
            .iter()
            .any(|f| f.ident.as_ref().map_or(false, |i| i == "position"));
        let has_layer = entity
            .fields
            .iter()
            .any(|f| f.ident.as_ref().map_or(false, |i| i == "layer"));
        let has_created_at = entity
            .fields
            .iter()
            .any(|f| f.ident.as_ref().map_or(false, |i| i == "created_at"));
        let has_updated_at = entity
            .fields
            .iter()
            .any(|f| f.ident.as_ref().map_or(false, |i| i == "updated_at"));

        let mut injected_fields = Vec::new();
        if !has_id {
            injected_fields.push(quote! { pub id: crate::domain::id::TypedRecordId });
        }
        if !has_parent_container_id {
            injected_fields.push(quote! { pub parent_container_id: Option<crate::domain::id::TypedRecordId> });
        }
        if !has_pos {
            injected_fields.push(quote! { pub position: crate::domain::base_models::Coordinates });
        }
        if !has_layer {
            injected_fields.push(quote! { pub layer: String });
        }
        if !has_created_at {
            injected_fields.push(quote! { pub created_at: i64 });
        }
        if !has_updated_at {
            injected_fields.push(quote! { pub updated_at: i64 });
        }

        let user_fields = &entity.fields;

        let mut field_schema_gen = Vec::new();
        let mut cleaned_user_fields = Vec::new();

        for field in user_fields {
            let mut cleaned_field = field.clone();
            cleaned_field.attrs.retain(|a| {
                !a.path().is_ident("surql_type") && !a.path().is_ident("surql_default")
            });
            cleaned_user_fields.push(cleaned_field);

            if let Some(field_name) = &field.ident {
                let fname_str = field_name.to_string();
                if ["id", "parent_container_id", "position", "layer", "created_at", "updated_at"]
                    .contains(&fname_str.as_str())
                {
                    continue;
                }

                let field_ty = &field.ty;

                let mut type_override: Option<String> = None;
                let mut default_override: Option<String> = None;

                for attr in &field.attrs {
                    if attr.path().is_ident("surql_type") {
                        if let Ok(l) = attr.parse_args::<syn::LitStr>() {
                            type_override = Some(l.value());
                        }
                    } else if attr.path().is_ident("surql_default") {
                        if let Ok(l) = attr.parse_args::<syn::LitStr>() {
                            default_override = Some(l.value());
                        }
                    }
                }

                let type_ov_tok = match type_override {
                    Some(val) => quote!(Some(#val)),
                    None => quote!(None),
                };
                let def_ov_tok = match default_override {
                    Some(val) => quote!(Some(#val)),
                    None => quote!(None),
                };

                field_schema_gen.push(quote! {
                    lines.extend(crate::domain::nodes::generate_field_schema_lines(
                        table,
                        #fname_str,
                        #type_ov_tok,
                        #def_ov_tok,
                        < #field_ty as crate::domain::nodes::SurqlSchemaField >::field_type(),
                        < #field_ty as crate::domain::nodes::SurqlSchemaField >::sub_field_paths(),
                    ));
                });
            }
        }

        struct_tokens.push(quote! {
            #(#attrs)*
            #[derive(Debug, Clone, surrealdb::types::SurrealValue, centrode_macros::SurrealTable, centrode_macros::NodeEntity)]
            #vis struct #name {
                #(#injected_fields,)*
                #(#cleaned_user_fields,)*
            }

            impl #name {
                pub const LABEL: &'static str = #label;
            }

            impl crate::domain::nodes::IsNode for #name {
                fn id(&self) -> &crate::domain::id::TypedRecordId {
                    &self.id
                }
                fn set_id(&mut self, id: crate::domain::id::TypedRecordId) {
                    self.id = id;
                }
                fn parent_container_id(&self) -> Option<&crate::domain::id::TypedRecordId> {
                    self.parent_container_id.as_ref()
                }
                fn set_parent_container_id(&mut self, val: Option<crate::domain::id::TypedRecordId>) {
                    self.parent_container_id = val;
                }
                fn position(&self) -> &crate::domain::base_models::Coordinates {
                    &self.position
                }
                fn position_mut(&mut self) -> &mut crate::domain::base_models::Coordinates {
                    &mut self.position
                }
                fn layer(&self) -> &str {
                    &self.layer
                }
                fn set_layer(&mut self, layer: String) {
                    self.layer = layer;
                }
                fn created_at(&self) -> i64 {
                    self.created_at
                }
                fn set_created_at(&mut self, val: i64) {
                    self.created_at = val;
                }
                fn updated_at(&self) -> i64 {
                    self.updated_at
                }
                fn set_updated_at(&mut self, val: i64) {
                    self.updated_at = val;
                }
                fn table_name(&self) -> &'static str {
                    Self::LABEL
                }
                fn serialize_node(self) -> surrealdb::types::Value {
                    use surrealdb::types::SurrealValue;
                    < Self as SurrealValue >::into_value(self)
                }
            }

            impl crate::domain::nodes::SurqlSchema for #name {
                fn generate_fields_schema(table: &str) -> Vec<String> {
                    let mut lines = Vec::new();
                    lines.push(crate::domain::schema::generate_created_at(table, true));
                    lines.push(crate::domain::schema::generate_updated_at(table));
                    lines.extend(crate::domain::nodes::generate_field_schema_lines(
                        table,
                        "parent_container_id",
                        None,
                        None,
                        < Option<crate::domain::id::TypedRecordId> as crate::domain::nodes::SurqlSchemaField >::field_type(),
                        < Option<crate::domain::id::TypedRecordId> as crate::domain::nodes::SurqlSchemaField >::sub_field_paths(),
                    ));
                    lines.extend(crate::domain::nodes::generate_field_schema_lines(
                        table,
                        "position",
                        None,
                        None,
                        < crate::domain::base_models::Coordinates as crate::domain::nodes::SurqlSchemaField >::field_type(),
                        < crate::domain::base_models::Coordinates as crate::domain::nodes::SurqlSchemaField >::sub_field_paths(),
                    ));
                    lines.extend(crate::domain::nodes::generate_field_schema_lines(
                        table,
                        "layer",
                        None,
                        None,
                        < String as crate::domain::nodes::SurqlSchemaField >::field_type(),
                        < String as crate::domain::nodes::SurqlSchemaField >::sub_field_paths(),
                    ));
                    #(#field_schema_gen)*
                    lines
                }
            }
        });

        enum_variants.push(quote! { #name(#name) });
        tables_slice.push(quote! { #label });
        schema_arms.push(quote! { (#label, <#name as crate::domain::schema::SurqlSchema>::generate_fields_schema(#label)) });
        from_struct_arms.push(quote! { #label => Ok(Nodes::#name(<#name as surrealdb::types::SurrealValue>::from_value(value)?)) });

        id_arms.push(quote! { Self::#name(n) => n.id() });
        set_id_arms.push(quote! { Self::#name(n) => n.set_id(id) });
        parent_container_id_arms.push(quote! { Self::#name(n) => n.parent_container_id() });
        set_parent_container_id_arms.push(quote! { Self::#name(n) => n.set_parent_container_id(val) });
        pos_arms.push(quote! { Self::#name(n) => n.position() });
        pos_mut_arms.push(quote! { Self::#name(n) => n.position_mut() });
        layer_arms.push(quote! { Self::#name(n) => n.layer() });
        set_layer_arms.push(quote! { Self::#name(n) => n.set_layer(layer) });
        created_at_arms.push(quote! { Self::#name(n) => n.created_at() });
        set_created_at_arms.push(quote! { Self::#name(n) => n.set_created_at(val) });
        updated_at_arms.push(quote! { Self::#name(n) => n.updated_at() });
        set_updated_at_arms.push(quote! { Self::#name(n) => n.set_updated_at(val) });
        table_name_arms.push(quote! { Self::#name(n) => n.table_name() });
        serialize_node_arms.push(quote! { Self::#name(n) => n.serialize_node() });
    }

    quote! {
        #(#struct_tokens)*

        #[derive(Debug, Clone, surrealdb::types::SurrealValue)]
        pub enum Nodes {
            #(#enum_variants,)*
        }

        impl Nodes {
            pub const TABLES: &'static [&'static str] = &[
                #(#tables_slice,)*
            ];

            pub fn generate_all_fields_schemas() -> Vec<(&'static str, Vec<String>)> {
                vec![
                    #(#schema_arms,)*
                ]
            }

            pub fn from_struct_value(table: &str, value: surrealdb::types::Value) -> Result<Self, anyhow::Error> {
                use surrealdb::types::SurrealValue;
                match table {
                    #(#from_struct_arms,)*
                    other => Err(anyhow::anyhow!("Unknown node table: {}", other)),
                }
            }
        }

        impl crate::domain::nodes::IsNode for Nodes {
            fn id(&self) -> &crate::domain::id::TypedRecordId {
                match self {
                    #(#id_arms,)*
                }
            }

            fn set_id(&mut self, id: crate::domain::id::TypedRecordId) {
                match self {
                    #(#set_id_arms,)*
                }
            }

            fn parent_container_id(&self) -> Option<&crate::domain::id::TypedRecordId> {
                match self {
                    #(#parent_container_id_arms,)*
                }
            }

            fn set_parent_container_id(&mut self, val: Option<crate::domain::id::TypedRecordId>) {
                match self {
                    #(#set_parent_container_id_arms,)*
                }
            }

            fn position(&self) -> &crate::domain::base_models::Coordinates {
                match self {
                    #(#pos_arms,)*
                }
            }

            fn position_mut(&mut self) -> &mut crate::domain::base_models::Coordinates {
                match self {
                    #(#pos_mut_arms,)*
                }
            }

            fn layer(&self) -> &str {
                match self {
                    #(#layer_arms,)*
                }
            }

            fn set_layer(&mut self, layer: String) {
                match self {
                    #(#set_layer_arms,)*
                }
            }

            fn created_at(&self) -> i64 {
                match self {
                    #(#created_at_arms,)*
                }
            }

            fn set_created_at(&mut self, val: i64) {
                match self {
                    #(#set_created_at_arms,)*
                }
            }

            fn updated_at(&self) -> i64 {
                match self {
                    #(#updated_at_arms,)*
                }
            }

            fn set_updated_at(&mut self, val: i64) {
                match self {
                    #(#set_updated_at_arms,)*
                }
            }

            fn table_name(&self) -> &'static str {
                match self {
                    #(#table_name_arms,)*
                }
            }

            fn serialize_node(self) -> surrealdb::types::Value {
                match self {
                    #(#serialize_node_arms,)*
                }
            }
        }
    }
}
