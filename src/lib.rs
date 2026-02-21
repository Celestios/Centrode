mod frb_generated; /* AUTO INJECTED BY flutter_rust_bridge. This line may not be accurate, and you can change it according to your needs. */

pub mod bridge;
pub mod domain;
pub mod persistence;
pub mod format;
pub mod telemetry;

/// Initialize the Mycelium core with the telemetry subscriber.
/// This should be called once during app startup.
pub fn init_core() {
    telemetry::init_telemetry();
}