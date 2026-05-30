-- ============================================================================
-- schema.surql — full, idempotent schema for map/node application
-- Designed for SurrealDB 3.0+
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Tables
-- ---------------------------------------------------------------------------
DEFINE TABLE OVERWRITE INode SCHEMAFULL;
DEFINE TABLE OVERWRITE TaskNode SCHEMAFULL;
DEFINE TABLE OVERWRITE InterNode SCHEMAFULL;
DEFINE TABLE OVERWRITE IRelation TYPE RELATION SCHEMAFULL;
DEFINE TABLE OVERWRITE Tag SCHEMAFULL;
DEFINE TABLE OVERWRITE MapTheme SCHEMAFULL;
DEFINE TABLE OVERWRITE MapMetaData SCHEMALESS;
DEFINE TABLE OVERWRITE History SCHEMAFULL;
DEFINE TABLE OVERWRITE Template SCHEMALESS;

-- ---------------------------------------------------------------------------
-- 2. Fields for `INode`
-- ---------------------------------------------------------------------------

-- content: object
DEFINE FIELD OVERWRITE content ON TABLE INode TYPE object;
DEFINE FIELD OVERWRITE content.text ON TABLE INode TYPE string;
DEFINE FIELD OVERWRITE content.blocks ON TABLE INode TYPE array;
DEFINE FIELD OVERWRITE content.blocks.* ON TABLE INode TYPE object;
DEFINE FIELD OVERWRITE content.blocks.*.block_type ON TABLE INode TYPE any;
DEFINE FIELD OVERWRITE content.blocks.*.content ON TABLE INode TYPE array;
DEFINE FIELD OVERWRITE content.blocks.*.content.* ON TABLE INode TYPE object;
DEFINE FIELD OVERWRITE content.blocks.*.content.*.inline_type ON TABLE INode TYPE any;
DEFINE FIELD OVERWRITE content.blocks.*.content.*.text ON TABLE INode TYPE string;
DEFINE FIELD OVERWRITE content.blocks.*.content.*.marks ON TABLE INode TYPE option<array>;
DEFINE FIELD OVERWRITE content.blocks.*.content.*.marks.* ON TABLE INode TYPE object;
DEFINE FIELD OVERWRITE content.blocks.*.content.*.marks.*.mark_type ON TABLE INode TYPE any;
DEFINE FIELD OVERWRITE content.blocks.*.content.*.marks.*.attrs ON TABLE INode TYPE option<object>;
DEFINE FIELD OVERWRITE content.blocks.*.content.*.marks.*.attrs.href ON TABLE INode TYPE option<string>;
DEFINE FIELD OVERWRITE content.blocks.*.attrs ON TABLE INode TYPE option<object>;
DEFINE FIELD OVERWRITE content.blocks.*.attrs.level ON TABLE INode TYPE option<int>;
DEFINE FIELD OVERWRITE content.blocks.*.attrs.language ON TABLE INode TYPE option<string>;

-- position: object
DEFINE FIELD OVERWRITE position ON TABLE INode TYPE object;
DEFINE FIELD OVERWRITE position.x ON TABLE INode TYPE int;
DEFINE FIELD OVERWRITE position.y ON TABLE INode TYPE int;

-- size: object
DEFINE FIELD OVERWRITE size ON TABLE INode TYPE object;
DEFINE FIELD OVERWRITE size.width ON TABLE INode TYPE int;
DEFINE FIELD OVERWRITE size.height ON TABLE INode TYPE int;

-- comments: array<object>
DEFINE FIELD OVERWRITE comments ON TABLE INode TYPE array;
DEFINE FIELD OVERWRITE comments.* ON TABLE INode TYPE object;
DEFINE FIELD OVERWRITE comments.*.text ON TABLE INode TYPE string;
DEFINE FIELD OVERWRITE comments.*.created_at ON TABLE INode TYPE int;

-- style: option<object>
DEFINE FIELD OVERWRITE style ON TABLE INode TYPE option<object>;
DEFINE FIELD OVERWRITE style.bg_color ON TABLE INode TYPE int;
DEFINE FIELD OVERWRITE style.stroke_color ON TABLE INode TYPE int;
DEFINE FIELD OVERWRITE style.stroke_width ON TABLE INode TYPE int;
DEFINE FIELD OVERWRITE style.font_family ON TABLE INode TYPE string;
DEFINE FIELD OVERWRITE style.font_size ON TABLE INode TYPE float;
DEFINE FIELD OVERWRITE style.shape ON TABLE INode TYPE string;
DEFINE FIELD OVERWRITE style.width ON TABLE INode TYPE int;
DEFINE FIELD OVERWRITE style.height ON TABLE INode TYPE int;
DEFINE FIELD OVERWRITE style.text_color ON TABLE INode TYPE int;
DEFINE FIELD OVERWRITE style.border_radius ON TABLE INode TYPE float;
DEFINE FIELD OVERWRITE style.padding ON TABLE INode TYPE float;
DEFINE FIELD OVERWRITE style.shadow_color ON TABLE INode TYPE int;
DEFINE FIELD OVERWRITE style.shadow_blur ON TABLE INode TYPE float;
DEFINE FIELD OVERWRITE style.shadow_spread ON TABLE INode TYPE float;
DEFINE FIELD OVERWRITE style.shadow_offset_x ON TABLE INode TYPE float;
DEFINE FIELD OVERWRITE style.shadow_offset_y ON TABLE INode TYPE float;
DEFINE FIELD OVERWRITE style.strategy_type ON TABLE INode TYPE string;

-- resolved_style: option<object>
DEFINE FIELD OVERWRITE resolved_style ON TABLE INode TYPE option<object>;
DEFINE FIELD OVERWRITE resolved_style.bg_color ON TABLE INode TYPE int;
DEFINE FIELD OVERWRITE resolved_style.stroke_color ON TABLE INode TYPE int;
DEFINE FIELD OVERWRITE resolved_style.stroke_width ON TABLE INode TYPE int;
DEFINE FIELD OVERWRITE resolved_style.font_family ON TABLE INode TYPE string;
DEFINE FIELD OVERWRITE resolved_style.font_size ON TABLE INode TYPE float;
DEFINE FIELD OVERWRITE resolved_style.shape ON TABLE INode TYPE string;
DEFINE FIELD OVERWRITE resolved_style.width ON TABLE INode TYPE int;
DEFINE FIELD OVERWRITE resolved_style.height ON TABLE INode TYPE int;
DEFINE FIELD OVERWRITE resolved_style.text_color ON TABLE INode TYPE int;
DEFINE FIELD OVERWRITE resolved_style.border_radius ON TABLE INode TYPE float;
DEFINE FIELD OVERWRITE resolved_style.padding ON TABLE INode TYPE float;
DEFINE FIELD OVERWRITE resolved_style.shadow_color ON TABLE INode TYPE int;
DEFINE FIELD OVERWRITE resolved_style.shadow_blur ON TABLE INode TYPE float;
DEFINE FIELD OVERWRITE resolved_style.shadow_spread ON TABLE INode TYPE float;
DEFINE FIELD OVERWRITE resolved_style.shadow_offset_x ON TABLE INode TYPE float;
DEFINE FIELD OVERWRITE resolved_style.shadow_offset_y ON TABLE INode TYPE float;
DEFINE FIELD OVERWRITE resolved_style.strategy_type ON TABLE INode TYPE string;

-- layout: option<object>
DEFINE FIELD OVERWRITE layout ON TABLE INode TYPE option<object>;
DEFINE FIELD OVERWRITE layout.strategy_type ON TABLE INode TYPE string;

-- resolved_layout: option<object>
DEFINE FIELD OVERWRITE resolved_layout ON TABLE INode TYPE option<object>;
DEFINE FIELD OVERWRITE resolved_layout.strategy_type ON TABLE INode TYPE string;

DEFINE FIELD OVERWRITE is_expanded ON TABLE INode TYPE bool;
DEFINE FIELD OVERWRITE expandable ON TABLE INode TYPE bool;
DEFINE FIELD OVERWRITE layer ON TABLE INode TYPE string;
DEFINE FIELD OVERWRITE locked ON TABLE INode TYPE bool;
DEFINE FIELD OVERWRITE tags ON TABLE INode TYPE array<record<Tag>>;
DEFINE FIELD OVERWRITE aliases ON TABLE INode TYPE array<string>;
DEFINE FIELD OVERWRITE attachment ON TABLE INode TYPE option<string>;
DEFINE FIELD OVERWRITE significance ON TABLE INode TYPE int DEFAULT 0;
DEFINE FIELD OVERWRITE line_count ON TABLE INode TYPE int DEFAULT 1;
DEFINE FIELD OVERWRITE created_at ON TABLE INode TYPE int;
DEFINE FIELD OVERWRITE updated_at ON TABLE INode COMPUTED time::millis(time::now());

-- ---------------------------------------------------------------------------
-- 3. Fields for `TaskNode`
-- ---------------------------------------------------------------------------

-- content: object
DEFINE FIELD OVERWRITE content ON TABLE TaskNode TYPE object;
DEFINE FIELD OVERWRITE content.text ON TABLE TaskNode TYPE string;
DEFINE FIELD OVERWRITE content.blocks ON TABLE TaskNode TYPE array;
DEFINE FIELD OVERWRITE content.blocks.* ON TABLE TaskNode TYPE object;
DEFINE FIELD OVERWRITE content.blocks.*.block_type ON TABLE TaskNode TYPE any;
DEFINE FIELD OVERWRITE content.blocks.*.content ON TABLE TaskNode TYPE array;
DEFINE FIELD OVERWRITE content.blocks.*.content.* ON TABLE TaskNode TYPE object;
DEFINE FIELD OVERWRITE content.blocks.*.content.*.inline_type ON TABLE TaskNode TYPE any;
DEFINE FIELD OVERWRITE content.blocks.*.content.*.text ON TABLE TaskNode TYPE string;
DEFINE FIELD OVERWRITE content.blocks.*.content.*.marks ON TABLE TaskNode TYPE option<array>;
DEFINE FIELD OVERWRITE content.blocks.*.content.*.marks.* ON TABLE TaskNode TYPE object;
DEFINE FIELD OVERWRITE content.blocks.*.content.*.marks.*.mark_type ON TABLE TaskNode TYPE any;
DEFINE FIELD OVERWRITE content.blocks.*.content.*.marks.*.attrs ON TABLE TaskNode TYPE option<object>;
DEFINE FIELD OVERWRITE content.blocks.*.content.*.marks.*.attrs.href ON TABLE TaskNode TYPE option<string>;
DEFINE FIELD OVERWRITE content.blocks.*.attrs ON TABLE TaskNode TYPE option<object>;
DEFINE FIELD OVERWRITE content.blocks.*.attrs.level ON TABLE TaskNode TYPE option<int>;
DEFINE FIELD OVERWRITE content.blocks.*.attrs.language ON TABLE TaskNode TYPE option<string>;

-- position: object
DEFINE FIELD OVERWRITE position ON TABLE TaskNode TYPE object;
DEFINE FIELD OVERWRITE position.x ON TABLE TaskNode TYPE int;
DEFINE FIELD OVERWRITE position.y ON TABLE TaskNode TYPE int;

-- size: object
DEFINE FIELD OVERWRITE size ON TABLE TaskNode TYPE object;
DEFINE FIELD OVERWRITE size.width ON TABLE TaskNode TYPE int;
DEFINE FIELD OVERWRITE size.height ON TABLE TaskNode TYPE int;

-- style: option<object>
DEFINE FIELD OVERWRITE style ON TABLE TaskNode TYPE option<object>;
DEFINE FIELD OVERWRITE style.bg_color ON TABLE TaskNode TYPE int;
DEFINE FIELD OVERWRITE style.stroke_color ON TABLE TaskNode TYPE int;
DEFINE FIELD OVERWRITE style.stroke_width ON TABLE TaskNode TYPE int;
DEFINE FIELD OVERWRITE style.font_family ON TABLE TaskNode TYPE string;
DEFINE FIELD OVERWRITE style.font_size ON TABLE TaskNode TYPE float;
DEFINE FIELD OVERWRITE style.shape ON TABLE TaskNode TYPE string;
DEFINE FIELD OVERWRITE style.width ON TABLE TaskNode TYPE int;
DEFINE FIELD OVERWRITE style.height ON TABLE TaskNode TYPE int;
DEFINE FIELD OVERWRITE style.text_color ON TABLE TaskNode TYPE int;
DEFINE FIELD OVERWRITE style.border_radius ON TABLE TaskNode TYPE float;
DEFINE FIELD OVERWRITE style.padding ON TABLE TaskNode TYPE float;
DEFINE FIELD OVERWRITE style.shadow_color ON TABLE TaskNode TYPE int;
DEFINE FIELD OVERWRITE style.shadow_blur ON TABLE TaskNode TYPE float;
DEFINE FIELD OVERWRITE style.shadow_spread ON TABLE TaskNode TYPE float;
DEFINE FIELD OVERWRITE style.shadow_offset_x ON TABLE TaskNode TYPE float;
DEFINE FIELD OVERWRITE style.shadow_offset_y ON TABLE TaskNode TYPE float;
DEFINE FIELD OVERWRITE style.strategy_type ON TABLE TaskNode TYPE string;

-- resolved_style: option<object>
DEFINE FIELD OVERWRITE resolved_style ON TABLE TaskNode TYPE option<object>;
DEFINE FIELD OVERWRITE resolved_style.bg_color ON TABLE TaskNode TYPE int;
DEFINE FIELD OVERWRITE resolved_style.stroke_color ON TABLE TaskNode TYPE int;
DEFINE FIELD OVERWRITE resolved_style.stroke_width ON TABLE TaskNode TYPE int;
DEFINE FIELD OVERWRITE resolved_style.font_family ON TABLE TaskNode TYPE string;
DEFINE FIELD OVERWRITE resolved_style.font_size ON TABLE TaskNode TYPE float;
DEFINE FIELD OVERWRITE resolved_style.shape ON TABLE TaskNode TYPE string;
DEFINE FIELD OVERWRITE resolved_style.width ON TABLE TaskNode TYPE int;
DEFINE FIELD OVERWRITE resolved_style.height ON TABLE TaskNode TYPE int;
DEFINE FIELD OVERWRITE resolved_style.text_color ON TABLE TaskNode TYPE int;
DEFINE FIELD OVERWRITE resolved_style.border_radius ON TABLE TaskNode TYPE float;
DEFINE FIELD OVERWRITE resolved_style.padding ON TABLE TaskNode TYPE float;
DEFINE FIELD OVERWRITE resolved_style.shadow_color ON TABLE TaskNode TYPE int;
DEFINE FIELD OVERWRITE resolved_style.shadow_blur ON TABLE TaskNode TYPE float;
DEFINE FIELD OVERWRITE resolved_style.shadow_spread ON TABLE TaskNode TYPE float;
DEFINE FIELD OVERWRITE resolved_style.shadow_offset_x ON TABLE TaskNode TYPE float;
DEFINE FIELD OVERWRITE resolved_style.shadow_offset_y ON TABLE TaskNode TYPE float;
DEFINE FIELD OVERWRITE resolved_style.strategy_type ON TABLE TaskNode TYPE string;

-- layout: option<object>
DEFINE FIELD OVERWRITE layout ON TABLE TaskNode TYPE option<object>;
DEFINE FIELD OVERWRITE layout.strategy_type ON TABLE TaskNode TYPE string;

-- resolved_layout: option<object>
DEFINE FIELD OVERWRITE resolved_layout ON TABLE TaskNode TYPE option<object>;
DEFINE FIELD OVERWRITE resolved_layout.strategy_type ON TABLE TaskNode TYPE string;

DEFINE FIELD OVERWRITE is_expanded ON TABLE TaskNode TYPE bool;
DEFINE FIELD OVERWRITE expandable ON TABLE TaskNode TYPE bool;
DEFINE FIELD OVERWRITE layer ON TABLE TaskNode TYPE string;
DEFINE FIELD OVERWRITE due_date ON TABLE TaskNode TYPE option<int>;
DEFINE FIELD OVERWRITE state ON TABLE TaskNode TYPE any;
DEFINE FIELD OVERWRITE created_at ON TABLE TaskNode TYPE int;
DEFINE FIELD OVERWRITE significance ON TABLE TaskNode TYPE int DEFAULT 0;
DEFINE FIELD OVERWRITE updated_at ON TABLE TaskNode COMPUTED time::millis(time::now());

-- ---------------------------------------------------------------------------
-- 4. Fields for `InterNode`
-- ---------------------------------------------------------------------------
DEFINE FIELD OVERWRITE position ON TABLE InterNode TYPE object;
DEFINE FIELD OVERWRITE position.x ON TABLE InterNode TYPE int;
DEFINE FIELD OVERWRITE position.y ON TABLE InterNode TYPE int;

DEFINE FIELD OVERWRITE style ON TABLE InterNode TYPE option<string>;
DEFINE FIELD OVERWRITE verb ON TABLE InterNode TYPE string;
DEFINE FIELD OVERWRITE behavioral_features ON TABLE InterNode TYPE option<string>;
DEFINE FIELD OVERWRITE layer ON TABLE InterNode TYPE string;
DEFINE FIELD OVERWRITE created_at ON TABLE InterNode TYPE int;
DEFINE FIELD OVERWRITE updated_at ON TABLE InterNode COMPUTED time::millis(time::now());

-- ---------------------------------------------------------------------------
-- 5. Fields for `IRelation` (a relation table)
-- ---------------------------------------------------------------------------

DEFINE FIELD OVERWRITE style ON TABLE IRelation TYPE option<object>;
DEFINE FIELD OVERWRITE style.bg_color ON TABLE IRelation TYPE int;
DEFINE FIELD OVERWRITE style.stroke_color ON TABLE IRelation TYPE int;
DEFINE FIELD OVERWRITE style.stroke_width ON TABLE IRelation TYPE int;
DEFINE FIELD OVERWRITE style.font_family ON TABLE IRelation TYPE string;
DEFINE FIELD OVERWRITE style.font_size ON TABLE IRelation TYPE float;
DEFINE FIELD OVERWRITE style.shape ON TABLE IRelation TYPE string;
DEFINE FIELD OVERWRITE style.arrow_type ON TABLE IRelation TYPE string;
DEFINE FIELD OVERWRITE style.arrow_size ON TABLE IRelation TYPE float;
DEFINE FIELD OVERWRITE style.width ON TABLE IRelation TYPE int;
DEFINE FIELD OVERWRITE style.height ON TABLE IRelation TYPE int;
DEFINE FIELD OVERWRITE style.text_color ON TABLE IRelation TYPE int;
DEFINE FIELD OVERWRITE style.shadow_color ON TABLE IRelation TYPE int;
DEFINE FIELD OVERWRITE style.shadow_blur ON TABLE IRelation TYPE float;
DEFINE FIELD OVERWRITE style.shadow_offset_x ON TABLE IRelation TYPE float;
DEFINE FIELD OVERWRITE style.shadow_offset_y ON TABLE IRelation TYPE float;
DEFINE FIELD OVERWRITE style.strategy_type ON TABLE IRelation TYPE string;
DEFINE FIELD OVERWRITE style.stroke_pattern ON TABLE IRelation TYPE string;

DEFINE FIELD OVERWRITE resolved_style ON TABLE IRelation TYPE option<object>;
DEFINE FIELD OVERWRITE resolved_style.bg_color ON TABLE IRelation TYPE int;
DEFINE FIELD OVERWRITE resolved_style.stroke_color ON TABLE IRelation TYPE int;
DEFINE FIELD OVERWRITE resolved_style.stroke_width ON TABLE IRelation TYPE int;
DEFINE FIELD OVERWRITE resolved_style.font_family ON TABLE IRelation TYPE string;
DEFINE FIELD OVERWRITE resolved_style.font_size ON TABLE IRelation TYPE float;
DEFINE FIELD OVERWRITE resolved_style.shape ON TABLE IRelation TYPE string;
DEFINE FIELD OVERWRITE resolved_style.arrow_type ON TABLE IRelation TYPE string;
DEFINE FIELD OVERWRITE resolved_style.arrow_size ON TABLE IRelation TYPE float;
DEFINE FIELD OVERWRITE resolved_style.width ON TABLE IRelation TYPE int;
DEFINE FIELD OVERWRITE resolved_style.height ON TABLE IRelation TYPE int;
DEFINE FIELD OVERWRITE resolved_style.text_color ON TABLE IRelation TYPE int;
DEFINE FIELD OVERWRITE resolved_style.shadow_color ON TABLE IRelation TYPE int;
DEFINE FIELD OVERWRITE resolved_style.shadow_blur ON TABLE IRelation TYPE float;
DEFINE FIELD OVERWRITE resolved_style.shadow_offset_x ON TABLE IRelation TYPE float;
DEFINE FIELD OVERWRITE resolved_style.shadow_offset_y ON TABLE IRelation TYPE float;
DEFINE FIELD OVERWRITE resolved_style.strategy_type ON TABLE IRelation TYPE string;
DEFINE FIELD OVERWRITE resolved_style.stroke_pattern ON TABLE IRelation TYPE string;

DEFINE FIELD OVERWRITE layout ON TABLE IRelation TYPE option<object>;
DEFINE FIELD OVERWRITE layout.from_side ON TABLE IRelation TYPE string;
DEFINE FIELD OVERWRITE layout.to_side ON TABLE IRelation TYPE string;
DEFINE FIELD OVERWRITE layout.strategy_type ON TABLE IRelation TYPE string;

DEFINE FIELD OVERWRITE resolved_layout ON TABLE IRelation TYPE option<object>;
DEFINE FIELD OVERWRITE resolved_layout.from_side ON TABLE IRelation TYPE string;
DEFINE FIELD OVERWRITE resolved_layout.to_side ON TABLE IRelation TYPE string;
DEFINE FIELD OVERWRITE resolved_layout.strategy_type ON TABLE IRelation TYPE string;

DEFINE FIELD OVERWRITE in ON TABLE IRelation TYPE record<INode | TaskNode | InterNode>;
DEFINE FIELD OVERWRITE out ON TABLE IRelation TYPE record<INode | TaskNode | InterNode>;
DEFINE FIELD OVERWRITE verb ON TABLE IRelation TYPE string;
DEFINE FIELD OVERWRITE directionless ON TABLE IRelation TYPE bool;
DEFINE FIELD OVERWRITE layer ON TABLE IRelation TYPE string;
DEFINE FIELD OVERWRITE created_at ON TABLE IRelation TYPE int;
DEFINE FIELD OVERWRITE updated_at ON TABLE IRelation COMPUTED time::millis(time::now());

-- ---------------------------------------------------------------------------
-- 6. Fields for `Tag`
-- ---------------------------------------------------------------------------
DEFINE FIELD OVERWRITE name ON TABLE Tag TYPE string;
DEFINE FIELD OVERWRITE color ON TABLE Tag TYPE int;
DEFINE FIELD OVERWRITE created_at ON TABLE Tag TYPE int;
DEFINE FIELD OVERWRITE updated_at ON TABLE Tag COMPUTED time::millis(time::now());
-- ---------------------------------------------------------------------------
-- 7. Fields for `MapMetaData`
-- ---------------------------------------------------------------------------
DEFINE FIELD OVERWRITE map_name ON TABLE MapMetaData TYPE string;
DEFINE FIELD OVERWRITE created_at ON TABLE MapMetaData TYPE int DEFAULT time::millis(time::now());
DEFINE FIELD OVERWRITE viewport_state ON TABLE MapMetaData TYPE object;
DEFINE FIELD OVERWRITE viewport_state.x_offset ON TABLE MapMetaData TYPE float;
DEFINE FIELD OVERWRITE viewport_state.y_offset ON TABLE MapMetaData TYPE float;
DEFINE FIELD OVERWRITE viewport_state.zoom_level ON TABLE MapMetaData TYPE float;
DEFINE FIELD OVERWRITE viewport_state.active_view ON TABLE MapMetaData TYPE string;
DEFINE FIELD OVERWRITE active_theme_id ON TABLE MapMetaData TYPE option<string>;
DEFINE FIELD OVERWRITE display_mode ON TABLE MapMetaData TYPE any;

-- ---------------------------------------------------------------------------
-- 8. Fields for `MapTheme`
-- ---------------------------------------------------------------------------
DEFINE FIELD OVERWRITE name ON TABLE MapTheme TYPE string;
DEFINE FIELD OVERWRITE primary_color ON TABLE MapTheme TYPE int;
DEFINE FIELD OVERWRITE secondary_color ON TABLE MapTheme TYPE int;
DEFINE FIELD OVERWRITE accent_color ON TABLE MapTheme TYPE int;
DEFINE FIELD OVERWRITE scaffold_background_color ON TABLE MapTheme TYPE int;
DEFINE FIELD OVERWRITE card_color ON TABLE MapTheme TYPE int;
DEFINE FIELD OVERWRITE divider_color ON TABLE MapTheme TYPE int;
DEFINE FIELD OVERWRITE text_color ON TABLE MapTheme TYPE int;
DEFINE FIELD OVERWRITE font_family ON TABLE MapTheme TYPE string;
DEFINE FIELD OVERWRITE body_font_size ON TABLE MapTheme TYPE float;
DEFINE FIELD OVERWRITE body_font_weight ON TABLE MapTheme TYPE any;
DEFINE FIELD OVERWRITE body_text_color ON TABLE MapTheme TYPE int;
DEFINE FIELD OVERWRITE border_radius ON TABLE MapTheme TYPE float;
DEFINE FIELD OVERWRITE app_bar_background_color ON TABLE MapTheme TYPE int;
DEFINE FIELD OVERWRITE app_bar_foreground_color ON TABLE MapTheme TYPE int;
DEFINE FIELD OVERWRITE app_bar_elevation ON TABLE MapTheme TYPE float;
DEFINE FIELD OVERWRITE app_bar_title_font_size ON TABLE MapTheme TYPE float;
DEFINE FIELD OVERWRITE app_bar_title_font_weight ON TABLE MapTheme TYPE any;
DEFINE FIELD OVERWRITE use_material3 ON TABLE MapTheme TYPE bool;
DEFINE FIELD OVERWRITE brightness ON TABLE MapTheme TYPE any;

-- ---------------------------------------------------------------------------
-- 9. Fields for `History`
-- ---------------------------------------------------------------------------
DEFINE FIELD OVERWRITE action_type ON TABLE History TYPE string;
DEFINE FIELD OVERWRITE payload ON TABLE History TYPE any;
DEFINE FIELD OVERWRITE status ON TABLE History TYPE string;
DEFINE FIELD OVERWRITE created_at ON TABLE History;

-- ---------------------------------------------------------------------------
-- 10. Analyzer (Required before indexes that use it)
-- ---------------------------------------------------------------------------
DEFINE ANALYZER IF NOT EXISTS simple TOKENIZERS blank, class FILTERS lowercase;

-- ---------------------------------------------------------------------------
-- 11. Indexes
-- ---------------------------------------------------------------------------

-- Simple indexes
DEFINE INDEX OVERWRITE node_tags ON TABLE INode FIELDS tags[*];
DEFINE INDEX OVERWRITE task_due_date ON TABLE TaskNode FIELDS due_date;
DEFINE INDEX OVERWRITE unique_relation ON TABLE IRelation FIELDS in, out, verb UNIQUE;

-- Content structure indexes for `INode`
DEFINE INDEX OVERWRITE content_bold_marks ON TABLE INode
    FIELDS content.blocks[*].content[*].marks[*].mark_type;
DEFINE INDEX OVERWRITE content_links ON TABLE INode
    FIELDS content.blocks[*].content[*].marks[*].attrs.href;
DEFINE INDEX OVERWRITE content_headings ON TABLE INode
    FIELDS content.blocks[*].block_type;

-- Full‑text search on `INode`
DEFINE INDEX OVERWRITE content_text_search ON TABLE INode
    FIELDS content.text
    FULLTEXT ANALYZER simple BM25 HIGHLIGHTS;

-- Content structure indexes for `TaskNode`
DEFINE INDEX OVERWRITE task_content_bold_marks ON TABLE TaskNode
    FIELDS content.blocks[*].content[*].marks[*].mark_type;
DEFINE INDEX OVERWRITE task_content_links ON TABLE TaskNode
    FIELDS content.blocks[*].content[*].marks[*].attrs.href;
DEFINE INDEX OVERWRITE task_content_headings ON TABLE TaskNode
    FIELDS content.blocks[*].block_type;

-- Full‑text search on `TaskNode`
DEFINE INDEX OVERWRITE task_content_text_search ON TABLE TaskNode
    FIELDS content.text
    FULLTEXT ANALYZER simple BM25 HIGHLIGHTS;