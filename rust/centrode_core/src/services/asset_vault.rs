use crate::domain::nodes::Attachment;
use sha2::{Digest, Sha256};
use std::path::{Path, PathBuf};
use uuid::Uuid;

pub struct AssetVault;

impl AssetVault {
    /// Computes the hex SHA-256 hash string for raw binary bytes
    pub fn compute_hash(bytes: &[u8]) -> String {
        let mut hasher = Sha256::new();
        hasher.update(bytes);
        format!("{:x}", hasher.finalize())
    }

    /// Ingests a media buffer into the CAS asset vault directory and returns populated metadata
    pub fn ingest_bytes(
        asset_dir: &str,
        file_name: &str,
        bytes: &[u8],
        mime_type: &str,
    ) -> Result<Attachment, anyhow::Error> {
        let hash = Self::compute_hash(bytes);
        let ext = Path::new(file_name)
            .extension()
            .and_then(|e| e.to_str())
            .unwrap_or_else(|| match mime_type {
                "image/png" => "png",
                "image/jpeg" | "image/jpg" => "jpg",
                "image/webp" => "webp",
                "image/gif" => "gif",
                "audio/mp3" | "audio/mpeg" => "mp3",
                "audio/wav" => "wav",
                "application/pdf" => "pdf",
                _ => "bin",
            });

        let target_dir = Path::new(asset_dir);
        if !target_dir.exists() {
            std::fs::create_dir_all(target_dir)?;
        }

        let target_file_name = format!("{}.{}", hash, ext);
        let target_file_path = target_dir.join(&target_file_name);

        if !target_file_path.exists() {
            std::fs::write(&target_file_path, bytes)?;
        }

        Ok(Attachment {
            id: Uuid::new_v4().to_string(),
            hash,
            name: file_name.to_string(),
            mime_type: mime_type.to_string(),
            byte_size: bytes.len() as i64,
            width: None,
            height: None,
            duration_ms: None,
        })
    }

    /// Resolves the absolute filesystem path for a stored asset hash and extension
    pub fn resolve_path(asset_dir: &str, hash: &str, extension: &str) -> PathBuf {
        let ext = extension.trim_start_matches('.');
        Path::new(asset_dir).join(format!("{}.{}", hash, ext))
    }
}
