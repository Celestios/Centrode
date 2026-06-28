use surrealdb::engine::local::Db;
use surrealdb::Surreal;

pub mod nodes;
pub mod relations;
pub mod tags;
pub mod templates;
pub mod patches;
pub mod analysis;

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
