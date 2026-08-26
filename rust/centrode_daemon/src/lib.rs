pub mod custodian;
pub mod domain;
pub mod engine;
pub mod ipc;
pub mod models;
pub mod schema;
pub mod schema_gen;
pub mod services;
pub mod tray;

pub use custodian::*;
pub use domain::*;
pub use engine::EngineManager;
pub use models::MapDescriptor;
pub use schema::{Schema, Seeder};
pub use services::DaemonService;

use anyhow::{Context, Result};
use std::path::PathBuf;

pub struct DaemonWorker {
    storage_path: PathBuf,
    service: DaemonService,
}

impl DaemonWorker {
    pub async fn start(storage_path: PathBuf) -> Result<Self> {
        let path_str = storage_path
            .to_str()
            .context("storage path is not valid UTF-8")?;

        tracing::info!("Daemon: acquiring SurrealKV lock via EngineManager at {}", path_str);

        let mut attempts = 0;
        loop {
            match EngineManager::init(path_str).await {
                Ok(()) => break,
                Err(e) => {
                    attempts += 1;
                    if attempts >= 5 {
                        return Err(e).context("Failed to acquire SurrealKV lock after retries");
                    }
                    tracing::warn!("Daemon: storage lock busy, retrying in 100ms (attempt {}/5)...", attempts);
                    tokio::time::sleep(tokio::time::Duration::from_millis(100)).await;
                }
            }
        }

        let service = DaemonService::new().await?;

        tracing::info!("Daemon: SurrealKV lock acquired and DaemonService initialized");

        Ok(Self {
            storage_path,
            service,
        })
    }

    pub fn service(&self) -> &DaemonService {
        &self.service
    }

    pub async fn flush_and_release(self) -> Result<()> {
        tracing::info!("Daemon: shutting down EngineManager and releasing lock...");
        EngineManager::shutdown().await?;
        tracing::info!("Daemon: SurrealKV lock released");
        Ok(())
    }

    pub fn spawn_app(&self, map_id: Option<&str>) -> Result<()> {
        let exe_path = std::env::current_exe()
            .context("Daemon: failed to get current exe path")?
            .parent()
            .context("Daemon: exe has no parent dir")?
            .join("centrode.exe");

        let mut args = Vec::new();
        if let Some(id) = map_id {
            args.push("--map".to_string());
            args.push(id.to_string());
        }

        tracing::info!("Daemon: spawning {:?} with args {:?}", exe_path, args);

        std::process::Command::new(&exe_path)
            .args(&args)
            .spawn()
            .context("Daemon: failed to spawn centrode.exe")?;

        Ok(())
    }

    pub fn storage_path(&self) -> &PathBuf {
        &self.storage_path
    }
}

pub fn default_storage_path() -> PathBuf {
    directories::ProjectDirs::from("com", "centrode", "centrode")
        .map(|pd| pd.data_local_dir().join("data"))
        .unwrap_or_else(|| PathBuf::from("centrode_data"))
}

pub fn handle_ipc_message(msg: ipc::IpcMessage, active_state: &str) -> ipc::IpcResponse {
    match msg {
        ipc::IpcMessage::OpenMap {
            map_id,
            map_name,
            cent_file_path,
        } => {
            tracing::info!(
                "IPC: OpenMap request for map_id={}, name={:?}, cent_file={:?}",
                map_id,
                map_name,
                cent_file_path,
            );
            ipc::IpcResponse {
                success: true,
                active_state: active_state.to_string(),
                message: Some(format!("Opening map {}", map_id)),
            }
        }
        ipc::IpcMessage::YieldBaton { target_process } => {
            tracing::info!("IPC: YieldBaton request to {}", target_process);
            ipc::IpcResponse {
                success: true,
                active_state: active_state.to_string(),
                message: Some("Baton yielded".to_string()),
            }
        }
        ipc::IpcMessage::FocusWindow => {
            tracing::info!("IPC: FocusWindow request");
            ipc::IpcResponse {
                success: true,
                active_state: active_state.to_string(),
                message: None,
            }
        }
        ipc::IpcMessage::Ping => ipc::IpcResponse {
            success: true,
            active_state: active_state.to_string(),
            message: Some("pong".to_string()),
        },
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_handle_ping() {
        let resp = handle_ipc_message(ipc::IpcMessage::Ping, "daemon");
        assert!(resp.success);
        assert_eq!(resp.active_state, "daemon");
        assert_eq!(resp.message.as_deref(), Some("pong"));
    }

    #[test]
    fn test_handle_open_map() {
        let resp = handle_ipc_message(
            ipc::IpcMessage::OpenMap {
                map_id: "test123".into(),
                map_name: Some("Test".into()),
                cent_file_path: None,
            },
            "daemon",
        );
        assert!(resp.success);
        assert!(resp.message.unwrap().contains("test123"));
    }
}
