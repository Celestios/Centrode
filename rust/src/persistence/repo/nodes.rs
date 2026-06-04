use crate::domain::base_models::{IsTable, MapData, Record};
use crate::domain::nodes::{IsNode, Nodes};
use crate::domain::relations::IRelation;
use crate::domain::snapshot::GraphSnapshot;
use crate::persistence::repo::Repository;

use anyhow::Result;
use surrealdb::types::{RecordId, SurrealValue, Value};
use tracing::info;

impl Repository {
    pub async fn create_node<N>(&self, input: N) -> Result<()>
    where
        N: IsNode,
    {
        let table = input.table_name();
        let key = input.key().to_string();
        let val = input.serialize_node();
        let _: Option<Value> = self
            .db
            .create((table, key.clone()))
            .content(val)
            .await?;
        info!("REPO: Created Node of table {} with ID: {}", table, key);
        Ok(())
    }

    pub async fn get_node(&self, table: String, key: String) -> Result<Option<Nodes>> {
        let fetch_fields = Nodes::fetch_fields_for_table(&table);
        let query_str = if fetch_fields.is_empty() {
            "SELECT * FROM $id".to_string()
        } else {
            format!("SELECT * FROM $id FETCH {}", fetch_fields.join(", "))
        };

        let mut res = self
            .db
            .query(query_str)
            .bind(("id", RecordId::new(table.clone(), key)))
            .await?;
        let val: Option<Value> = res.take(0)?;

        if let Some(v) = val {
            let node = Nodes::from_struct_value(&table, v)?;
            return Ok(Some(node));
        }
        Ok(None)
    }

    pub async fn update_node<N>(&self, input: N) -> Result<()>
    where
        N: IsNode,
    {
        let table = input.table_name();
        let key = input.key().to_string();
        let val = input.serialize_node();
        let _: Option<Value> = self
            .db
            .update((table, key.clone()))
            .content(val)
            .await?;
        info!("REPO: Updated Node of table {} with ID: {}", table, key);
        Ok(())
    }

    pub async fn delete_node(&self, table: String, key: String) -> Result<()> {
        let query = "
            BEGIN TRANSACTION;
            DELETE IRelation WHERE in = $target OR out = $target;
            DELETE $target;
            COMMIT TRANSACTION;
        ";
        let record_id = RecordId::new(table, key);
        tracing::trace!(
            "REPO: BEGIN TRANSACTION for cascading delete of {:?}",
            record_id
        );
        self.db
            .query(query)
            .bind(("target", record_id.clone()))
            .await?;

        Ok(())
    }

    pub async fn fetch_table_nodes<N, F>(&self) -> Result<Vec<N>>
    where
        N: IsTable + From<(String, F)>,
        F: surrealdb::types::SurrealValue,
    {
        let table = N::LABEL;
        let fetch_fields = N::FETCH_FIELDS;
        let query_str = if fetch_fields.is_empty() {
            format!("SELECT * FROM {}", table)
        } else {
            format!("SELECT * FROM {} FETCH {}", table, fetch_fields.join(", "))
        };

        let mut res = self.db.query(query_str).await?;
        let raw: Vec<Value> = res.take(0)?;

        let nodes = raw
            .into_iter()
            .filter_map(|val| {
                let record = Record::from_record_value(val)?;
                let (key, fields) = record.to_type::<F>()?;
                Some(N::from((key, fields)))
            })
            .collect();

        Ok(nodes)
    }

    pub async fn get_graph_snapshot(&self) -> Result<GraphSnapshot> {
        tracing::info!("Fetching graph snapshot...");

        let mut nodes = Vec::new();
        for &table in Nodes::TABLES {
            tracing::debug!("Fetching {}...", table);
            let fetch_fields = Nodes::fetch_fields_for_table(table);
            let query_str = if fetch_fields.is_empty() {
                format!("SELECT * FROM {}", table)
            } else {
                format!("SELECT * FROM {} FETCH {}", table, fetch_fields.join(", "))
            };

            let mut res = self.db.query(query_str).await?;
            let raw: Vec<Value> = res.take(0)?;

            for val in raw {
                match Nodes::from_struct_value(table, val) {
                    Ok(node) => nodes.push(node),
                    Err(e) => tracing::error!(
                        "Failed to parse node from table {}: {:?}",
                        table,
                        e
                    ),
                }
            }
        }

        tracing::debug!("Fetching IRelations...");
        let relations_raw: Vec<Value> = self.db.select(IRelation::LABEL).await?;
        let relations: Vec<IRelation> = relations_raw
            .into_iter()
            .filter_map(|val| IRelation::from_value(val).ok())
            .collect();
        tracing::debug!("Fetched {} IRelations", relations.len());

        tracing::debug!("Fetching MapMetadata...");
        let metadata: Option<MapData> = self.db.select((MapData::LABEL, MapData::KEY)).await?;
        let metadata = metadata.ok_or_else(|| anyhow::anyhow!("MapMetadata not found"))?;

        Ok(GraphSnapshot {
            nodes,
            relations,
            metadata,
        })
    }

    pub async fn clear_graph(&self) -> Result<()> {
        tracing::debug!("Clearing existing graph data...");

        let db = self.db.clone();
        let tx = db.begin().await?;

        tracing::debug!("Deleting existing IRelations...");
        let _: Vec<Value> = tx.delete(IRelation::LABEL).await?;
        tracing::debug!("Deleted all IRelations");

        for &table in Nodes::TABLES {
            tracing::debug!("Deleting existing {}...", table);
            let _: Vec<Value> = tx.delete(table).await?;
            tracing::debug!("Deleted all {}", table);
        }

        tracing::debug!("Deleting existing MapMetadata...");
        let _: Vec<Value> = tx.delete(MapData::LABEL).await?;
        tracing::debug!("Deleted all MapMetadata");

        tx.commit().await?;
        tracing::debug!("Graph cleared.");
        Ok(())
    }

    pub async fn set_graph_snapshot(&self, snapshot: GraphSnapshot) -> Result<()> {
        tracing::info!("Storing graph snapshot atomically...");

        self.clear_graph().await?;
        let db = self.db.clone();
        let tx = db.begin().await?;

        tracing::debug!("Inserting {} nodes...", snapshot.nodes.len());
        for node in snapshot.nodes {
            let (table, key) = {
                let (t, k) = node.table_and_key();
                (t, k.to_string())
            };
            let document = node.serialize_node();
            let _: Option<Value> = tx.create((table, key)).content(document).await?;
        }

        tracing::debug!("Inserting {} IRelations...", snapshot.relations.len());
        for relation in snapshot.relations {
            let in_id = relation.in_.clone();
            let out_id = relation.out.clone();
            let record = RecordId::new(IRelation::LABEL, relation.key.clone());

            let mut res = tx
                .query("RELATE $from -> $record -> $out CONTENT $data")
                .bind(("record", record))
                .bind(("from", in_id.into_record()))
                .bind(("out", out_id.into_record()))
                .bind(("data", relation))
                .await?;
            let _: Option<Value> = res.take(0)?;
        }

        tracing::debug!("Inserting MapMetadata...");
        let _: Option<MapData> = tx
            .create((MapData::LABEL, MapData::KEY))
            .content(snapshot.metadata)
            .await?;

        tx.commit().await?;
        tracing::info!("Graph snapshot stored successfully.");

        Ok(())
    }

    pub async fn query_search(&self, query: String) -> Result<Vec<Nodes>> {
        tracing::debug!("REPO: query_search called with query: {}", query);
        let trimmed = query.trim();
        let query_str = if trimmed.to_uppercase().starts_with("WHERE") {
            format!("SELECT * FROM INode, TaskNode, InterNode {}", trimmed)
        } else {
            "SELECT * FROM INode, TaskNode WHERE content.text ~ $query".to_string()
        };

        let mut req = self.db.query(&query_str);
        if !trimmed.to_uppercase().starts_with("WHERE") {
            req = req.bind(("query", query));
        }

        let mut res = req.await?;
        let records: Vec<Value> = res.take(0)?;
        let mut nodes = Vec::new();

        for val in records {
            if let Value::Object(ref obj) = val {
                if let Some(Value::RecordId(rid)) = obj.get("id") {
                    let table = rid.table.clone();
                    if let Ok(node) = Nodes::from_struct_value(&table, val) {
                        nodes.push(node);
                    }
                }
            }
        }

        Ok(nodes)
    }
}
