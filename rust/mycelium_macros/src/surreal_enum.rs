use proc_macro::TokenStream;
use quote::quote;
use syn::{parse_macro_input, Data, DeriveInput};

fn to_snake_case(s: &str) -> String {
    let mut acc = String::new();
    let chars: Vec<char> = s.chars().collect();

    for (i, &ch) in chars.iter().enumerate() {
        if ch.is_uppercase() {
            if i > 0 {
                let prev = chars[i - 1];
                if prev.is_lowercase()
                    || (prev.is_uppercase()
                        && i + 1 < chars.len()
                        && chars[i + 1].is_lowercase())
                {
                    acc.push('_');
                }
            }
            acc.push(ch.to_ascii_lowercase());
        } else {
            acc.push(ch);
        }
    }
    acc
}

pub fn derive_surreal_db_enum_impl(input: TokenStream) -> TokenStream {
    let input = parse_macro_input!(input as DeriveInput);
    let name = &input.ident;

    let Data::Enum(data_enum) = &input.data else {
        panic!("SurrealDbEnum can only be derived on enums");
    };

    let mut to_str_arms = Vec::new();
    let mut from_bytes_arms = Vec::new();
    let mut from_u8_arms = Vec::new();

    for variant in &data_enum.variants {
        let v_ident = &variant.ident;
        let v_str = to_snake_case(&v_ident.to_string());
        let v_bytes = syn::LitByteStr::new(v_str.as_bytes(), v_ident.span());

        let Some((_, expr)) = &variant.discriminant else {
            return syn::Error::new_spanned(
                variant,
                format!(
                    "SurrealDbEnum variant `{}::{}` must have an explicit integer discriminant assignment (e.g. {} = 0)",
                    name, v_ident, v_ident
                ),
            )
            .to_compile_error()
            .into();
        };

        to_str_arms.push(quote! {
            Self::#v_ident => #v_str
        });

        from_bytes_arms.push(quote! {
            #v_bytes => Ok(Self::#v_ident)
        });

        from_u8_arms.push(quote! {
            #expr => Ok(Self::#v_ident)
        });
    }

    let expanded = quote! {
        impl crate::domain::traits::SurrealDbEnum for #name {
            #[inline]
            fn to_u8(&self) -> u8 {
                *self as u8
            }

            #[inline]
            fn from_u8(val: u8) -> Result<Self, anyhow::Error> {
                match val {
                    #(#from_u8_arms,)*
                    _ => Err(anyhow::anyhow!("Unknown {} enum discriminant integer: {}", stringify!(#name), val)),
                }
            }

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
                surrealdb::types::Kind::Int
            }

            fn into_value(self) -> surrealdb::types::Value {
                surrealdb::types::Value::Number(surrealdb::types::Number::from(self as u8 as i64))
            }

            fn from_value(value: surrealdb::types::Value) -> Result<Self, surrealdb::types::Error> {
                match value {
                    surrealdb::types::Value::Number(n) => {
                        let i_val = match n {
                            surrealdb::types::Number::Int(i) => i,
                            surrealdb::types::Number::Float(f) => f as i64,
                            _ => return Err(surrealdb::types::Error::thrown(format!("Invalid number for {}", stringify!(#name)))),
                        };
                        let u_val = u8::try_from(i_val).map_err(|e| surrealdb::types::Error::thrown(e.to_string()))?;
                        crate::domain::traits::SurrealDbEnum::from_u8(u_val)
                            .map_err(|e| surrealdb::types::Error::thrown(e.to_string()))
                    }
                    surrealdb::types::Value::String(s) => {
                        crate::domain::traits::SurrealDbEnum::from_surreal_bytes(s.as_bytes())
                            .map_err(|e| surrealdb::types::Error::thrown(e.to_string()))
                    }
                    unsupported => Err(surrealdb::types::Error::thrown(format!("Expected Int for {}, found: {:?}", stringify!(#name), unsupported))),
                }
            }
        }

        impl crate::domain::schema::SurqlSchemaField for #name {
            fn field_type() -> String {
                "int".to_string()
            }
            fn sub_field_paths() -> Vec<(String, String)> {
                vec![]
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
