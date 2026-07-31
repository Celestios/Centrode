use syn::{
    parse::{Parse, ParseStream},
    Attribute, Field, Ident, Result, Token, Visibility,
};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum CategoryKind {
    Node,
    Relation,
    Auxiliary,
}

#[derive(Debug, Clone)]
pub struct TableAttr {
    pub label: Option<String>,
    pub fetch_fields: Vec<String>,
    pub no_key: bool,
}

#[derive(Debug, Clone)]
pub struct EntityDef {
    pub category: CategoryKind,
    pub table_attr: TableAttr,
    pub attrs: Vec<Attribute>,
    pub vis: Visibility,
    pub name: Ident,
    pub fields: Vec<Field>,
}

pub struct TypeSystemInput {
    pub entities: Vec<EntityDef>,
}

impl Parse for TypeSystemInput {
    fn parse(input: ParseStream) -> Result<Self> {
        let mut entities = Vec::new();
        while !input.is_empty() {
            let outer_attrs = input.call(Attribute::parse_outer)?;
            let mut category = None;
            let mut remaining_attrs = Vec::new();
            let mut label = None;
            let mut fetch_fields = Vec::new();
            let mut no_key = false;

            for attr in outer_attrs {
                if attr.path().is_ident("category") {
                    let cat_ident: Ident = attr.parse_args()?;
                    let cat_str = cat_ident.to_string();
                    match cat_str.as_str() {
                        "node" => category = Some(CategoryKind::Node),
                        "relation" => category = Some(CategoryKind::Relation),
                        "auxiliary" => category = Some(CategoryKind::Auxiliary),
                        _ => {
                            return Err(syn::Error::new_spanned(
                                cat_ident,
                                "Unknown category. Expected node, relation, or auxiliary",
                            ))
                        }
                    }
                } else if attr.path().is_ident("table") {
                    attr.parse_nested_meta(|meta| {
                        if meta.path.is_ident("label") {
                            let value: syn::LitStr = meta.value()?.parse()?;
                            label = Some(value.value());
                            Ok(())
                        } else if meta.path.is_ident("no_key") {
                            no_key = true;
                            Ok(())
                        } else if meta.path.is_ident("fetch") {
                            let value_stream = meta.value()?;
                            let content;
                            syn::bracketed!(content in value_stream);
                            let syn_punctuated: syn::punctuated::Punctuated<
                                syn::LitStr,
                                Token![,],
                            > = syn::punctuated::Punctuated::parse_terminated(&content)?;
                            for lit in syn_punctuated {
                                fetch_fields.push(lit.value());
                            }
                            Ok(())
                        } else {
                            Err(meta.error("unrecognized table attribute key"))
                        }
                    })?;
                } else {
                    remaining_attrs.push(attr);
                }
            }

            let category = match category {
                Some(cat) => cat,
                None => {
                    return Err(input
                        .error("Missing #[category(node|relation|auxiliary)] attribute on struct"))
                }
            };

            let vis: Visibility = input.parse()?;
            input.parse::<Token![struct]>()?;
            let name: Ident = input.parse()?;

            let content;
            syn::braced!(content in input);
            let fields_punctuated: syn::punctuated::Punctuated<Field, Token![,]> =
                content.parse_terminated(Field::parse_named, Token![,])?;
            let fields: Vec<Field> = fields_punctuated.into_iter().collect();

            entities.push(EntityDef {
                category,
                table_attr: TableAttr {
                    label,
                    fetch_fields,
                    no_key,
                },
                attrs: remaining_attrs,
                vis,
                name,
                fields,
            });
        }

        Ok(TypeSystemInput { entities })
    }
}
