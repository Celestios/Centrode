use centrode_daemon::{default_storage_path, tray, DaemonWorker};
use std::path::PathBuf;

fn main() {
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

    let rt = match tokio::runtime::Builder::new_multi_thread()
        .enable_all()
        .build()
    {
        Ok(rt) => rt,
        Err(e) => {
            tracing::error!("Daemon: failed to build runtime: {}", e);
            std::process::exit(1);
        }
    };

    let worker = match rt.block_on(DaemonWorker::start(storage_path)) {
        Ok(w) => w,
        Err(e) => {
            tracing::error!("Daemon: failed to start: {}", e);
            std::process::exit(1);
        }
    };

    let _ = tray::init_tray();

    let custodian = centrode_daemon::CustodianManager::new();

    if let Err(e) = custodian.run_loop(worker, rt) {
        tracing::error!("Daemon: custodian loop error: {}", e);
    }
}
