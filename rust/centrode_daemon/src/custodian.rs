use anyhow::{Context, Result};
use std::path::PathBuf;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;

use crate::ipc::{self, IpcMessage, IpcResponse, IpcServer};
use crate::DaemonWorker;

pub struct CustodianManager {
    storage_path: PathBuf,
    running: Arc<AtomicBool>,
}

impl CustodianManager {
    pub fn new(storage_path: PathBuf) -> Self {
        Self {
            storage_path,
            running: Arc::new(AtomicBool::new(true)),
        }
    }

    /// Spawns the main Centrode application executable detached.
    pub fn launch_application(&self, map_id: Option<&str>) -> Result<()> {
        let exe_path = Self::find_app_executable()?;
        let mut cmd = std::process::Command::new(&exe_path);
        if let Some(id) = map_id {
            cmd.args(["--map", id]);
        }
        tracing::info!("CustodianManager: launching application at {:?}", exe_path);
        cmd.spawn()
            .context("CustodianManager: failed to spawn centrode.exe")?;
        Ok(())
    }

    /// Resolves the path to the main application executable (centrode.exe).
    pub fn find_app_executable() -> Result<PathBuf> {
        let current_exe = std::env::current_exe().context("failed to get current_exe")?;
        let current_dir = current_exe.parent().context("exe has no parent directory")?;

        // 1. Adjacent to daemon executable (release package / install location)
        let adjacent = current_dir.join("centrode.exe");
        if adjacent.exists() {
            return Ok(adjacent);
        }

        // 2. Flutter build output (debug/release runner directory)
        let root_candidates = [
            current_dir.join("../../../build/windows/x64/runner/Release/centrode.exe"),
            current_dir.join("../../../build/windows/x64/runner/Debug/centrode.exe"),
            current_dir.join("../../build/windows/x64/runner/Release/centrode.exe"),
            current_dir.join("../../build/windows/x64/runner/Debug/centrode.exe"),
        ];

        for candidate in root_candidates {
            if let Ok(canon) = candidate.canonicalize() {
                if canon.exists() {
                    return Ok(canon);
                }
            }
        }

        // Fallback to adjacent even if not yet existing at runtime check
        Ok(adjacent)
    }

    fn release_worker_lock(worker_slot: &std::sync::Mutex<Option<DaemonWorker>>) -> Result<()> {
        let mut lock = worker_slot
            .lock()
            .map_err(|_| anyhow::anyhow!("Daemon worker mutex poisoned"))?;
        if let Some(dw) = lock.take() {
            let rt = tokio::runtime::Builder::new_current_thread()
                .enable_all()
                .build()
                .context("Failed to build Tokio runtime for lock release")?;
            rt.block_on(dw.flush_and_release())?;
        }
        Ok(())
    }

    /// Serves the IPC loop with automatic baton yielding and app launch.
    pub fn run_loop(&self, worker: DaemonWorker) -> Result<()> {
        let pipe = IpcServer::new(ipc::IPC_PIPE_NAME);
        let worker_slot = std::sync::Mutex::new(Some(worker));
        let running = self.running.clone();

        tracing::info!(
            "CustodianManager: running daemon baton loop on {}",
            ipc::IPC_PIPE_NAME
        );

        while running.load(Ordering::SeqCst) {
            let handler = |msg: IpcMessage| -> IpcResponse {
                match msg {
                    IpcMessage::Ping => IpcResponse {
                        success: true,
                        active_state: "daemon".into(),
                        message: Some("pong".into()),
                    },
                    IpcMessage::FocusWindow => IpcResponse {
                        success: true,
                        active_state: "daemon".into(),
                        message: None,
                    },
                    IpcMessage::OpenMap {
                        map_id,
                        map_name: _,
                        cent_file_path: _,
                    } => {
                        tracing::info!(
                            "CustodianManager: OpenMap received, yielding to app: {}",
                            map_id
                        );
                        if let Err(e) = Self::release_worker_lock(&worker_slot) {
                            tracing::error!("CustodianManager: Failed to release storage lock: {}", e);
                            return IpcResponse {
                                success: false,
                                active_state: "daemon".into(),
                                message: Some(format!("Failed to release storage lock: {e}")),
                            };
                        }
                        if let Err(e) = self.launch_application(Some(&map_id)) {
                            tracing::error!("CustodianManager: Failed to launch application: {}", e);
                            return IpcResponse {
                                success: false,
                                active_state: "daemon".into(),
                                message: Some(format!("Failed to launch application: {e}")),
                            };
                        }
                        running.store(false, Ordering::SeqCst);
                        IpcResponse {
                            success: true,
                            active_state: "app".into(),
                            message: Some(format!("Baton yielded to app for map {}", map_id)),
                        }
                    }
                    IpcMessage::YieldBaton { target_process } => {
                        tracing::info!(
                            "CustodianManager: YieldBaton received for {}",
                            target_process
                        );
                        if let Err(e) = Self::release_worker_lock(&worker_slot) {
                            tracing::error!("CustodianManager: Failed to release storage lock: {}", e);
                            return IpcResponse {
                                success: false,
                                active_state: "daemon".into(),
                                message: Some(format!("Failed to release storage lock: {e}")),
                            };
                        }
                        running.store(false, Ordering::SeqCst);
                        IpcResponse {
                            success: true,
                            active_state: target_process,
                            message: Some("Baton yielded".into()),
                        }
                    }
                }
            };

            if let Err(e) = pipe.accept_one(&handler) {
                tracing::warn!("CustodianManager: IPC accept error: {}", e);
            }

            if !running.load(Ordering::SeqCst) {
                tracing::info!("CustodianManager: baton yielded, terminating daemon process cleanly");
                break;
            }
        }

        Ok(())
    }
}
