use centrode_daemon::{default_storage_path, handle_ipc_message, ipc, DaemonWorker};
use std::path::PathBuf;

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "centrode_daemon=info".into()),
        )
        .init();

    let storage_path = std::env::args()
        .position(|a| a == "--data-dir")
        .and_then(|i| std::env::args().nth(i + 1))
        .map(PathBuf::from)
        .unwrap_or_else(default_storage_path);

    tracing::info!("centrode_daemon starting, data dir: {:?}", storage_path);

    let worker = match DaemonWorker::start(storage_path).await {
        Ok(w) => w,
        Err(e) => {
            tracing::error!("Daemon: failed to start: {}", e);
            std::process::exit(1);
        }
    };

    let pipe = ipc::IpcServer::new(ipc::IPC_PIPE_NAME);

    tracing::info!("Daemon: listening on IPC pipe {}", ipc::IPC_PIPE_NAME);
    tracing::info!("Daemon: idle loop running (0% CPU, awaiting IPC)");

    let _ = tray::init_tray();

    let storage_path = worker.storage_path().clone();

    let handler = |msg: ipc::IpcMessage| -> ipc::IpcResponse {
        handle_ipc_message(msg, "daemon")
    };

    if let Err(e) = pipe.serve(handler) {
        tracing::error!("Daemon: IPC server error: {}", e);
    }
}
