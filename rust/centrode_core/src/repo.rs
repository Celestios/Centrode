use surrealdb::engine::local::Db;
use surrealdb::Surreal;

pub mod analysis;
pub mod dictionaries;
pub mod history;
pub mod nodes;
pub mod patches;
pub mod relations;
pub mod snapshot;
pub mod tags;
pub mod templates;
pub mod themes;

#[derive(Clone)]
pub struct Repository {
    db: Surreal<Db>,
}

impl Repository {
    pub fn new(db: Surreal<Db>) -> Self {
        Self { db }
    }

    pub fn db(&self) -> &Surreal<Db> {
        &self.db
    }
}
