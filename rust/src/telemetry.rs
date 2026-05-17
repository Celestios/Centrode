// rust/src/telemetry.rs
//! Telemetry Layer for Mycelium – Pre-Stream Buffer with FFI Sink

use chrono::Utc;
use std::fs::OpenOptions;
use std::io::Write;
use std::sync::atomic::{AtomicBool, AtomicI64, Ordering};
use std::sync::{Arc, LazyLock, Mutex};
use tokio::sync::broadcast;
use tracing_subscriber::EnvFilter;
use tracing_subscriber::Layer;

// ============================================================================
// LogState – FFI Transfer Struct (same fields as the working version)
// ============================================================================

#[flutter_rust_bridge::frb]
#[derive(Debug, Clone, serde::Serialize)]
pub struct LogState {
    pub t_micro: i64,
    pub seq_id: i64,
    pub level: u8,
    pub message: String,
}

// ============================================================================
// Internal shared state
// ============================================================================

struct TelemetryState {
    buffer: Mutex<Vec<LogState>>,
    seq: AtomicI64,
    sender: broadcast::Sender<LogState>,
    connected: AtomicBool,
}

// ============================================================================
// TelemetryLayer – public handle (Clone, implements Layer directly)
// ============================================================================

#[derive(Clone)]
pub struct TelemetryLayer {
    state: Arc<TelemetryState>,
}

impl TelemetryLayer {
    fn new() -> Self {
        let (tx, _) = broadcast::channel(1024);
        Self {
            state: Arc::new(TelemetryState {
                buffer: Mutex::new(Vec::new()),
                seq: AtomicI64::new(0),
                sender: tx,
                connected: AtomicBool::new(false),
            }),
        }
    }
}

static TELEMETRY: LazyLock<TelemetryLayer> = LazyLock::new(TelemetryLayer::new);

impl TelemetryLayer {
    pub fn instance() -> Self {
        TELEMETRY.clone()
    }
}

// ============================================================================
// StringVisitor – unchanged
// ============================================================================

struct StringVisitor {
    message: String,
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

    fn record_str(&mut self, field: &tracing::field::Field, value: &str) {
        if field.name() == "message" {
            self.message = value.to_owned();
        }
    }
}

// ============================================================================
// Layer implementation directly on TelemetryLayer
// ============================================================================

impl<S: tracing::Subscriber> Layer<S> for TelemetryLayer {
    fn on_event(
        &self,
        event: &tracing::Event<'_>,
        _ctx: tracing_subscriber::layer::Context<'_, S>,
    ) {
        let t_micro = Utc::now().timestamp_micros();
        let s_id = self.state.seq.fetch_add(1, Ordering::Relaxed);
        let level = match *event.metadata().level() {
            tracing::Level::TRACE => 0,
            tracing::Level::DEBUG => 1,
            tracing::Level::INFO => 2,
            tracing::Level::WARN => 3,
            tracing::Level::ERROR => 4,
        };

        let mut visitor = StringVisitor::new();
        event.record(&mut visitor);

        let log_state = LogState {
            t_micro,
            seq_id: s_id,
            level,
            message: visitor.message,
        };

        if self.state.connected.load(Ordering::Acquire) {
            let _ = self.state.sender.send(log_state);
        } else {
            self.state.buffer.lock().unwrap().push(log_state);
        }
    }
}

// ============================================================================
// Public API
// ============================================================================

pub fn init_telemetry() {
    use tracing_subscriber::prelude::*;

    let filter = EnvFilter::new("info,mycelium_core=trace,surrealdb=warn");
    let layer = TelemetryLayer::instance();
    let subscriber = tracing_subscriber::registry().with(filter).with(layer);
    let _ = tracing::subscriber::set_global_default(subscriber);

    // NOTE: set_hook replaces any previously installed hook
    std::panic::set_hook(Box::new(|panic_info| {
        let timestamp = Utc::now().format("%Y-%m-%d %H:%M:%S%.3f");
        let msg = match panic_info.payload().downcast_ref::<&'static str>() {
            Some(s) => *s,
            None => match panic_info.payload().downcast_ref::<String>() {
                Some(s) => &s[..],
                None => "Box<dyn Any>",
            },
        };
        let location = panic_info
            .location()
            .unwrap_or_else(|| std::panic::Location::caller());
        let fatal_log = format!(
            "[{}] [5] [RUST-FATAL] Panic at {}: {}\n",
            timestamp, location, msg
        );
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

pub fn connect_log_stream() {
    let layer = TelemetryLayer::instance();
    layer.state.connected.store(true, Ordering::Relaxed);

    let mut buffer = layer.state.buffer.lock().unwrap();
    for log in buffer.drain(..) {
        let _ = layer.state.sender.send(log);
    }
}

pub fn subscribe_to_logs() -> broadcast::Receiver<LogState> {
    TelemetryLayer::instance().state.sender.subscribe()
}
