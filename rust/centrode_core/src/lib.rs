mod frb_generated; /* AUTO INJECTED BY flutter_rust_bridge. This line may not be accurate, and you can change it according to your needs. */

pub mod domain;
pub use domain::*;

pub mod bridge;
pub mod format;
pub mod layout_engine;
pub mod relation_engine;
pub mod repo;
pub mod persistence {
    pub use crate::repo::*;
}
pub mod services;
pub mod telemetry;

/// Initialize the Centrode core with the telemetry subscriber.
/// This should be called once during app startup.
pub fn init_core() {
    telemetry::init_telemetry();
}
