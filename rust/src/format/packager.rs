use crate::domain::base_models::MapConfig;
use crate::domain::nodes::NodeOutput;
use crate::domain::relations::IRelation;
use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};
use std::fs::{self, File};
use std::io::Write;
use std::path::Path;
use walkdir::WalkDir;
use zip::{write::FileOptions, ZipArchive};

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
    metadata: Option<MapConfig>,
) -> Result<()> {
    let path = Path::new(archive_path);
    let file = File::create(&path)
        .with_context(|| format!("Failed to create archive at {}", archive_path))?;

    let mut zip = zip::ZipWriter::new(file);

    // Speed: DEFLATE is standard. For max speed, could use Stored (0 compression),
    // but Deflated is the best balance for disk I/O vs CPU.
    let options = FileOptions::default()
        .compression_method(zip::CompressionMethod::Deflated)
        .unix_permissions(0o755);

    // 1. Serialize Graph Data (MessagePack)
    let snapshot = GraphSnapshot {
        version: "0.2.0".to_string(), // Bumped version
        metadata,
        nodes,
        relations,
    };

    // Binary serialization is ~5x faster than JSON
    let serialized_data = rmp_serde::to_vec(&snapshot)?;

    zip.start_file("graph.msgpack", options)?;
    zip.write_all(&serialized_data)?;

    // 2. Compress and include the Attachments folder (data/)
    // We walk the attachment_dir and replicate the structure inside the zip
    let walk_path = Path::new(attachment_dir);
    if walk_path.exists() {
        for entry in WalkDir::new(walk_path) {
            let entry = entry?;
            let path = entry.path();

            // Get relative path for zip entry name (e.g., "data/image.png")
            let name = path
                .strip_prefix(Path::new(attachment_dir).parent().unwrap_or(Path::new(".")))?
                .to_str()
                .context("Invalid UTF-8 path")?
                .replace("\\", "/"); // [FIX] Ensure forward slashes for ZIP compatibility on Windows

            if path.is_file() {
                zip.start_file(name, options)?;
                let mut f = File::open(path)?;
                std::io::copy(&mut f, &mut zip)?; // Stream directly
            } else if !name.is_empty() {
                zip.add_directory(name, options)?;
            }
        }
    }

    zip.finish()?;
    Ok(())
}

/// LOADER: Extracts Archive -> RAM Structs
pub fn load_project_from_celi(
    archive_path: &str,
    target_attachment_dir: &str,
) -> Result<(Vec<NodeOutput>, Vec<IRelation>, Option<MapConfig>)> {
    let file = File::open(archive_path)?;
    let mut zip = ZipArchive::new(file)?;

    // 1. Deserialize Brain
    let snapshot: GraphSnapshot = {
        let mut graph_file = zip.by_name("graph.msgpack")?;
        rmp_serde::from_read(&mut graph_file)?
    };

    // 2. Extract Body (Assets)
    // We iterate by index to avoid ownership issues with zip
    for i in 0..zip.len() {
        let mut file = zip.by_index(i)?;
        let name = file.name().to_owned();

        // Skip the DB file
        if name == "graph.msgpack" || name == "graph.json" {
            continue;
        }

        let outpath = Path::new(target_attachment_dir).join(&name);

        if file.is_dir() {
            fs::create_dir_all(&outpath)?;
        } else {
            if let Some(p) = outpath.parent() {
                fs::create_dir_all(p)?;
            }
            let mut outfile = File::create(&outpath)?;
            std::io::copy(&mut file, &mut outfile)?;
        }
    }

    Ok((snapshot.nodes, snapshot.relations, snapshot.metadata))
}
