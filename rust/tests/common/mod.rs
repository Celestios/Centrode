use rust_lib_mycelium::persistence::repo::Repository;
use rust_lib_mycelium::persistence::schema::Schema;
use surrealdb::engine::local::Mem;
use surrealdb::Surreal;

pub async fn setup_test_repo() -> Repository {
    // Initialize SurrealDB in-memory engine
    let db = Surreal::new::<Mem>(())
        .await
        .expect("Failed to initialize SurrealDB Mem engine");

    // Select test namespace and database
    db.use_ns("test_ns")
        .use_db("test_db")
        .await
        .expect("Failed to select test namespace and database");

    // Initialize Schema
    Schema::init(&db)
        .await
        .expect("Failed to initialize DB schema in tests");

    use rust_lib_mycelium::persistence::schema::Seeder;
    Seeder::seed_default_data(&db, "Test Map".to_string())
        .await
        .expect("Failed to seed default data in tests");

    Repository::new(db)
}

