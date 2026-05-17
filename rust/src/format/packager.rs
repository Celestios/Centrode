// src/format/packager.rs

use crate::domain::base_models::MapData;
use anyhow::{Context, Result};
use std::collections::BTreeMap;
use std::fs::{self, File};
use std::io::{Read, Write};
use std::path::Path;
use surrealdb::types::{Array, SurrealValue, Value};
use walkdir::WalkDir;
use zip::{write::FileOptions, ZipArchive, ZipWriter};

// -----------------------------------------------------------------------------
// Save – generic map of keys to Vec<Value>
// -----------------------------------------------------------------------------
pub fn save_project_to_celi(
    archive_path: &str,
    attachment_dir: &str,
    content: BTreeMap<String, Vec<Value>>,
    metadata: MapData,
) -> Result<()> {
    let mut root: BTreeMap<String, Value> = BTreeMap::new();
    root.insert("version".into(), Value::String("0.1.0".into()));
    root.insert("metadata".into(), metadata.into_value());

    for (key, values) in &content {
        root.insert(key.clone().into(), Value::Array(values.clone().into()));
    }

    let graph_value = Value::Object(root.into());
    let serialized_data =
        rmp_serde::to_vec(&graph_value).context("Failed to serialize graph snapshot")?;

    // Write the zip archive
    let path = Path::new(archive_path);
    let file = File::create(path)
        .with_context(|| format!("Failed to create archive at {}", archive_path))?;

    let mut zip = ZipWriter::new(file);
    let options = FileOptions::default()
        .compression_method(zip::CompressionMethod::Deflated)
        .unix_permissions(0o755);

    zip.start_file("graph.msgpack", options)?;
    zip.write_all(&serialized_data)?;

    // Embed attachments
    let walk_path = Path::new(attachment_dir);
    if walk_path.exists() {
        for entry in WalkDir::new(walk_path) {
            let entry = entry?;
            let path = entry.path();

            let name = path
                .strip_prefix(Path::new(attachment_dir).parent().unwrap_or(Path::new(".")))?
                .to_str()
                .context("Invalid UTF-8 path")?
                .replace('\\', "/");

            if path.is_file() {
                zip.start_file(name, options)?;
                let mut f = File::open(path)?;
                std::io::copy(&mut f, &mut zip)?;
            } else if !name.is_empty() {
                zip.add_directory(name, options)?;
            }
        }
    }

    zip.finish()?;
    Ok(())
}

// -----------------------------------------------------------------------------
// Load – returns a generic map of keys to Vec<Value>
// -----------------------------------------------------------------------------
pub fn load_project_from_celi(
    archive_path: &str,
    target_attachment_dir: &str,
) -> Result<(BTreeMap<String, Vec<Value>>, MapData)> {
    let file = File::open(archive_path)?;
    let mut zip = ZipArchive::new(file)?;

    // 1. Deserialize the graph value
    let graph_value: Value = {
        let mut graph_file = zip.by_name("graph.msgpack")?;
        let mut buf = Vec::new();
        graph_file.read_to_end(&mut buf)?;
        rmp_serde::from_slice(&buf).context("Failed to deserialize graph snapshot")?
    };

    let (content, metadata) = match graph_value {
        Value::Object(obj) => {
            let mut content = BTreeMap::new();
            let mut metadata_opt: Option<MapData> = None; // metadata is not optional later

            for (key, val) in &obj {
                if key == "version" {
                    continue;
                } else if key == "metadata" {
                    metadata_opt = Some(
                        MapData::from_value(val.clone()).context("Failed to convert metadata")?,
                    );
                } else {
                    let arr: &Array = val
                        .as_array()
                        .with_context(|| format!("Value for key '{}' is not an array", key))?;
                    let vec: Vec<Value> = arr.clone().into();
                    content.insert(key.clone(), vec);
                }
            }

            let metadata =
                metadata_opt.context("Missing required 'metadata' key in graph archive")?;
            (content, metadata)
        }
        _ => anyhow::bail!("Graph archive does not contain a valid top-level object"),
    };

    // 3. Extract attachments (unchanged)
    for i in 0..zip.len() {
        let mut file = zip.by_index(i)?;
        let name = file.name().to_owned();

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

    Ok((content, metadata))
}
