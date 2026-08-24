-- -----------------------------------------------------------------------------
-- CENTRODE SYSTEM DATABASE SCHEMA (centrode:system)
-- -----------------------------------------------------------------------------

DEFINE TABLE IF NOT EXISTS MapRegistry SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD IF NOT EXISTS name ON TABLE MapRegistry TYPE string;
DEFINE FIELD IF NOT EXISTS storage_path ON TABLE MapRegistry TYPE string;
DEFINE FIELD IF NOT EXISTS created_at_ms ON TABLE MapRegistry TYPE number;
DEFINE FIELD IF NOT EXISTS modified_at_ms ON TABLE MapRegistry TYPE number;
DEFINE FIELD IF NOT EXISTS accessed_at_ms ON TABLE MapRegistry TYPE number;

DEFINE TABLE IF NOT EXISTS SystemSetting SCHEMALESS PERMISSIONS FULL;
DEFINE FIELD IF NOT EXISTS value ON TABLE SystemSetting TYPE string;
