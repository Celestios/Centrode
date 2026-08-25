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
pub mod traits;

pub use analysis::SurrealLayoutRepository;
pub use dictionaries::SurrealDictionaryRepository;
pub use history::SurrealHistoryRepository;
pub use nodes::SurrealNodeRepository;
pub use relations::SurrealRelationRepository;
pub use snapshot::SurrealSnapshotRepository;
pub use tags::SurrealTagRepository;
pub use templates::SurrealTemplateRepository;
pub use themes::SurrealThemeRepository;
pub use traits::*;

#[derive(Clone)]
pub struct Repositories {
    pub nodes: SurrealNodeRepository,
    pub relations: SurrealRelationRepository,
    pub layout: SurrealLayoutRepository,
    pub history: SurrealHistoryRepository,
    pub themes: SurrealThemeRepository,
    pub templates: SurrealTemplateRepository,
    pub snapshot: SurrealSnapshotRepository,
    pub dictionaries: SurrealDictionaryRepository,
    pub tags: SurrealTagRepository,
}

impl Repositories {
    pub fn new(db: Surreal<Db>) -> Self {
        Self {
            nodes: SurrealNodeRepository::new(db.clone()),
            relations: SurrealRelationRepository::new(db.clone()),
            layout: SurrealLayoutRepository::new(db.clone()),
            history: SurrealHistoryRepository::new(db.clone()),
            themes: SurrealThemeRepository::new(db.clone()),
            templates: SurrealTemplateRepository::new(db.clone()),
            snapshot: SurrealSnapshotRepository::new(db.clone()),
            dictionaries: SurrealDictionaryRepository::new(db.clone()),
            tags: SurrealTagRepository::new(db),
        }
    }
}
