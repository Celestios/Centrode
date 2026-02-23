// rust/src/telemetry.rs
//! Telemetry Layer for Mycelium - Pre-Stream Buffer with FFI Sink
//!
//! This module implements an asynchronous observer pattern with isolate handshake
//! and pre-stream buffering. Logs are captured and buffered until the Dart side
//! establishes a connection via FFI stream.

use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::{Arc, Mutex};
use std::fs::OpenOptions;
use std::io::Write;
use chrono::Utc;
use tracing_subscriber::Layer;
use tracing_subscriber::EnvFilter;

// ============================================================================
// LogState - FFI Transfer Struct
// ============================================================================

/// LogState represents a single log entry for FFI transfer to Dart.
/// Designed for zero-copy efficiency with atomic sequencing.
#[flutter_rust_bridge::frb]
#[derive(Debug, Clone, serde::Serialize)]
pub struct LogState {
    /// Microseconds since Unix epoch (T)
    pub t_micro: i64,
    /// Atomic sequence counter for ordering reconstruction (S_id)
    pub s_id: u64,
    /// Log level: 0=Trace, 1=Debug, 2=Info, 3=Warn, 4=Error, 5=Fatal
    pub level: u8,
    /// Log message content
    pub message: String,
}

// ============================================================================
// Global State - Sink & Pre-Stream Buffer
// ============================================================================

lazy_static::lazy_static! {
    /// Pre-Stream Buffer - Holds logs until FFI stream is connected
    pub static ref PRE_STREAM_BUFFER: Arc<Mutex<Vec<LogState>>> = Arc::new(Mutex::new(Vec::new()));
    
    /// Atomic sequence counter for logical causal sequencing
    pub static ref RUST_SEQ_ID: AtomicU64 = AtomicU64::new(0);
    
    /// Global broadcast sender for log delivery to Dart side
    /// Uses tokio broadcast channel for efficient multi-consumer streaming
    pub static ref LOG_SENDER: tokio::sync::broadcast::Sender<LogState> = {
        let (tx, _rx) = tokio::sync::broadcast::channel(1024);
        tx
    };
    
    /// Flag indicating whether the FFI stream is connected
    pub static ref STREAM_CONNECTED: std::sync::atomic::AtomicBool = std::sync::atomic::AtomicBool::new(false);
}

// ============================================================================
// StringVisitor - Message Extraction Helper
// ============================================================================

/// Visitor for extracting the "message" field from tracing events
struct StringVisitor {
    pub message: String,
}

impl StringVisitor {
    fn new() -> Self {
        Self {
            message: String::new(),
        }
    }
}

impl tracing::field::Visit for StringVisitor {
    fn record_debug(&mut self, field: &tracing::field::Field, value: &dyn std::fmt::Debug) {
        if field.name() == "message" {
            self.message = format!("{:?}", value);
        }
    }
}

// ============================================================================
// FfiLoggerLayer - The Tracing Layer
// ============================================================================

/// FfiLoggerLayer intercepts tracing events and routes them to the FFI stream.
///
/// # Behavior
/// - If FFI Sink is active: Push event directly to stream
/// - If FFI Sink is not connected: Buffer event in PRE_STREAM_BUFFER
///
/// # Performance Notes
/// - Uses `Ordering::SeqCst` for atomic sequence generation
/// - Microsecond precision timestamps via chrono
pub struct FfiLoggerLayer {}

impl<S: tracing::Subscriber> Layer<S> for FfiLoggerLayer {
    fn on_event(&self, event: &tracing::Event<'_>, _ctx: tracing_subscriber::layer::Context<'_, S>) {
        // T: Microseconds since epoch
        let t_micro = Utc::now().timestamp_micros();
        
        // S_id: Atomic sequence with SeqCst ordering for causal consistency
        let s_id = RUST_SEQ_ID.fetch_add(1, Ordering::SeqCst);
        
        // Map tracing::Level to Mycelium Taxonomy (L0-L5)
        let level = match *event.metadata().level() {
            tracing::Level::TRACE => 0,
            tracing::Level::DEBUG => 1,
            tracing::Level::INFO => 2,
            tracing::Level::WARN => 3,
            tracing::Level::ERROR => 4,
        };

        // Extract message using visitor pattern
        let mut visitor = StringVisitor::new();
        event.record(&mut visitor);

        let log_state = LogState {
            t_micro,
            s_id,
            level,
            message: visitor.message,
        };

        // Check if stream is connected
        if STREAM_CONNECTED.load(Ordering::SeqCst) {
            // Send directly to broadcast channel
            let _ = LOG_SENDER.send(log_state);
        } else {
            // Buffer until stream connects
            PRE_STREAM_BUFFER.lock().unwrap().push(log_state);
        }
    }
}

// ============================================================================
// Initialization & Panic Hook
// ============================================================================

/// Initialize the telemetry layer with the global tracing subscriber.
/// Sets up the L5 FATAL panic hook for synchronous crash logging.
/// 
/// # Filter Configuration
/// - `mycelium_core=trace`: Allow TRACE level for our application code
/// - `surrealdb=warn`: Suppress noisy SurrealDB debug/trace logs
/// - Default level: INFO for all other crates
pub fn init_telemetry() {
    use tracing_subscriber::prelude::*;
    
    // Create a filter: Allow TRACE for our code, but restrict noisy crates
    // This prevents SurrealDB from flooding the FFI stream with debug/trace logs
    let filter = EnvFilter::new("info,mycelium_core=trace,surrealdb=warn");
    
    // Attach the filter to the registry with our FFI logger layer
    let subscriber = tracing_subscriber::registry()
        .with(filter)
        .with(FfiLoggerLayer {});
    let _ = tracing::subscriber::set_global_default(subscriber);

    // L5 FATAL PANIC HOOK
    // Synchronous I/O for crash scenarios - bypasses FFI/Async
    std::panic::set_hook(Box::new(|panic_info| {
        let timestamp = Utc::now().format("%Y-%m-%d %H:%M:%S%.3f");
        
        let msg = match panic_info.payload().downcast_ref::<&'static str>() {
            Some(s) => *s,
            None => match panic_info.payload().downcast_ref::<String>() {
                Some(s) => &s[..],
                None => "Box<dyn Any>",
            },
        };
        
        let location = panic_info.location().unwrap_or_else(|| std::panic::Location::caller());
        let fatal_log = format!(
            "[{}] [5] [RUST-FATAL] Panic at {}: {}\n",
            timestamp, location, msg
        );

        // Synchronous File Write (Bypass FFI/Async)
        if let Ok(mut file) = OpenOptions::new()
            .create(true)
            .append(true)
            .open("mycelium.log")
        {
            let _ = file.write_all(fatal_log.as_bytes());
            let _ = file.flush();
        }
    }));
}

/// Connect the FFI stream and flush the pre-stream buffer.
/// Called by Dart after the DiskWriterIsolate is ready.
pub fn connect_log_stream() {
    // Mark stream as connected
    STREAM_CONNECTED.store(true, Ordering::SeqCst);
    
    // Flush Pre-Stream Buffer to broadcast channel
    let mut buffer = PRE_STREAM_BUFFER.lock().unwrap();
    for log in buffer.drain(..) {
        let _ = LOG_SENDER.send(log);
    }
}

/// Get a receiver for the log stream.
/// Returns a broadcast receiver that yields LogState entries.
pub fn subscribe_to_logs() -> tokio::sync::broadcast::Receiver<LogState> {
    LOG_SENDER.subscribe()
}
