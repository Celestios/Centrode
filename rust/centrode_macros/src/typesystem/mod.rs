pub mod ast;
pub mod auxiliary_gen;
pub mod master_gen;
pub mod node_gen;
pub mod relation_gen;
pub mod table_kind;

use proc_macro::TokenStream;
use syn::parse_macro_input;

use ast::TypeSystemInput;
use auxiliary_gen::generate_auxiliary;
use master_gen::generate_master_entity;
use node_gen::generate_nodes;
use relation_gen::generate_relations;
use table_kind::generate_table_kind;

pub fn define_domain_types_impl(input: TokenStream) -> TokenStream {
    let input = parse_macro_input!(input as TypeSystemInput);

    let table_kind_tokens = generate_table_kind(&input.entities);
    let nodes_tokens = generate_nodes(&input.entities);
    let relations_tokens = generate_relations(&input.entities);
    let auxiliary_tokens = generate_auxiliary(&input.entities);
    let master_tokens = generate_master_entity();

    let expanded = quote::quote! {
        #table_kind_tokens
        #nodes_tokens
        #relations_tokens
        #auxiliary_tokens
        #master_tokens
    };

    TokenStream::from(expanded)
}
