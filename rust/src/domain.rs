//! Domain Tier Module Hierarchy
//! ============================
//!
//! Encapsulates core data models, schema metadata, and domain traits.
//!
//! Architectural Invariants:
//! -------------------------
//! - `types.rs`: Primary declaration site for domain structs via macro code generation.
//! - Submodules contain category-specific domain logic, traits, and enums.
//! - All generated entity structs and sum-type union enums are re-exported at the top level of `domain`.
//! - Submodules must remain cohesive to their domain responsibility without redundant entity wrapper modules.

pub mod base_models;
pub mod contents;
pub mod id;
pub mod nodes;
pub mod patches;
pub mod relations;
pub mod schema;
pub mod snapshot;
pub mod styles;
pub mod tags;
pub mod templates;
pub mod theme;
pub mod traits;
pub mod types;

pub use types::*;
