use crate::domain::nodes::NodeOutput;
use crate::domain::relations::IRelation;
use crate::domain::config::MapConfig;
use serde::{Serialize, Deserialize};
use std::fs::File;
use std::io::{Read, Write};
use std::path::Path;
use walkdir::WalkDir;
use zip::write::FileOptions;
use anyhow::{Context, Result};

// The schema for the internal graph.json file
#[derive(Serialize, Deserialize)]
struct GraphSnapshot {
    version: String,
    metadata: Option<MapConfig>,
    nodes: Vec<NodeOutput>,
    relations: Vec<IRelation>,
}

/// Creates a .celi archive containing the graph snapshot and attachments
pub fn save_project_to_celi(
    archive_path: &str,
    attachment_dir: &str,
    nodes: Vec<NodeOutput>,
    relations: Vec<IRelation>,
    metadata: Option<MapConfig>
) -> Result<()> {

    let path = Path::new(archive_path);
    let file = File::create(&path)
        .with_context(|| format!("Failed to create archive at {}", archive_path))?;

    let mut zip = zip::ZipWriter::new(file);
    let options = FileOptions::default()
        .compression_method(zip::CompressionMethod::Stored) // Use Deflated for actual compression
        .unix_permissions(0o755);

    // 1. Serialize and write the Graph Data (graph.json)
    let snapshot = GraphSnapshot {
        version: "0.1.0".to_string(),
        metadata,
        nodes,
        relations,
    };
    let json_data = serde_json::to_vec_pretty(&snapshot)?;

    zip.start_file("graph.json", options)?;
    zip.write_all(&json_data)?;

    // 2. Compress and include the Attachments folder (data/)
    // We walk the attachment_dir and replicate the structure inside the zip
    let walk_path = Path::new(attachment_dir);
    if walk_path.exists() {
        for entry in WalkDir::new(walk_path) {
            let entry = entry?;
            let path = entry.path();

            // Get relative path for zip entry name (e.g., "data/image.png")
            let name = path.strip_prefix(Path::new(attachment_dir).parent().unwrap_or(Path::new(".")))?
                .to_str()
                .context("Invalid UTF-8 path")?;

            if path.is_file() {
                zip.start_file(name, options)?;
                let mut f = File::open(path)?;
                let mut buffer = Vec::new();
                f.read_to_end(&mut buffer)?;
                zip.write_all(&buffer)?;
            } else if !name.is_empty() {
                zip.add_directory(name, options)?;
            }
        }
    }

    zip.finish()?;
    Ok(())
}