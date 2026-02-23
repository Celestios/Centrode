use serde::{Deserialize, Serialize};

// -----------------------------------------------------------------------------
// Core Identity & Spatial Types (Restored)
// -----------------------------------------------------------------------------

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct Comment {
    pub text: String,
    pub created_at: i64, // Unix microseconds
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct Coordinates {
    pub x: i32,
    pub y: i32,
    pub z: u8,
}

// -----------------------------------------------------------------------------
// Theme & Styling (Dumb Receiver Implementation)
// -----------------------------------------------------------------------------

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct Theme {
    #[serde(
        alias = "id",
        skip_serializing_if = "Option::is_none",
        with = "crate::domain::serde_helpers::option_thing_string"
    )]
    pub id: Option<String>,
    pub name: String,
    pub config: String, // Blind JSON blob from Flutter
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct ViewportState {
    pub x_offset: f64,
    pub y_offset: f64,
    pub zoom_level: f64,
    pub active_view: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct MapConfig {
    pub map_name: String,
    pub viewport_state: ViewportState,
    pub active_theme_id: Option<String>,
}

// -----------------------------------------------------------------------------
// Content Property & DocumentModel (New Implementation)
// -----------------------------------------------------------------------------

/// Primary source of truth for node content.
/// The `text` field is derived from `blocks` for search indexing in SurrealDB.
#[derive(Debug, Clone, Serialize, Deserialize, Default, PartialEq, Eq)]
pub struct Content {
    /// Plain text projection - used for search indexing.
    #[serde(default)]
    pub text: String,

    /// Native block structure - queryable logic
    #[serde(default)]
    pub blocks: Vec<ContentBlock>,
}

impl Content {
    /// Creates a new Content with the given blocks
    pub fn new(blocks: Vec<ContentBlock>) -> Self {
        let text = Self::compute_plain_text(&blocks);
        Content { text, blocks }
    }

    /// Creates a Content from plain text (creates a single paragraph block)
    pub fn from_plain_text(text: impl Into<String>) -> Self {
        let text = text.into();
        let blocks = if text.is_empty() {
            vec![]
        } else {
            vec![ContentBlock::paragraph(text.clone())]
        };
        Content { text, blocks }
    }

    /// Derive plain text for search indexing
    pub fn to_plain_text(&self) -> String {
        Self::compute_plain_text(&self.blocks)
    }

    /// Computes plain text from blocks
    fn compute_plain_text(blocks: &[ContentBlock]) -> String {
        let mut result = String::new();
        for block in blocks {
            for inline in &block.content {
                result.push_str(&inline.text);
            }
            result.push('\n');
        }
        // Remove trailing newline if present
        if result.ends_with('\n') {
            result.pop();
        }
        result
    }

    /// Updates the derived text field from blocks
    pub fn refresh_text(&mut self) {
        self.text = self.to_plain_text();
    }
}

// -----------------------------------------------------------------------------
// Block-Level Content
// -----------------------------------------------------------------------------

/// Block-level content (paragraphs, headings, lists)
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct ContentBlock {
    pub block_type: BlockType,
    pub content: Vec<InlineElement>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub attrs: Option<BlockAttrs>,
}

impl Default for ContentBlock {
    fn default() -> Self {
        Self::paragraph("")
    }
}

impl ContentBlock {
    /// Creates a new paragraph block with the given text
    pub fn paragraph(text: impl Into<String>) -> Self {
        ContentBlock {
            block_type: BlockType::Paragraph,
            content: vec![InlineElement::text(text)],
            attrs: None,
        }
    }

    /// Creates a new heading block with the given text and level
    pub fn heading(text: impl Into<String>, level: u8) -> Self {
        ContentBlock {
            block_type: BlockType::Heading,
            content: vec![InlineElement::text(text)],
            attrs: Some(BlockAttrs {
                level: Some(level),
                language: None,
            }),
        }
    }

    /// Creates a new code block with the given text and optional language
    pub fn code_block(text: impl Into<String>, language: Option<String>) -> Self {
        ContentBlock {
            block_type: BlockType::CodeBlock,
            content: vec![InlineElement::text(text)],
            attrs: Some(BlockAttrs {
                level: None,
                language,
            }),
        }
    }

    /// Creates a new bullet list item
    pub fn bullet_list(text: impl Into<String>) -> Self {
        ContentBlock {
            block_type: BlockType::BulletList,
            content: vec![InlineElement::text(text)],
            attrs: None,
        }
    }

    /// Creates a new ordered list item
    pub fn ordered_list(text: impl Into<String>) -> Self {
        ContentBlock {
            block_type: BlockType::OrderedList,
            content: vec![InlineElement::text(text)],
            attrs: None,
        }
    }

    /// Creates a new blockquote
    pub fn blockquote(text: impl Into<String>) -> Self {
        ContentBlock {
            block_type: BlockType::Blockquote,
            content: vec![InlineElement::text(text)],
            attrs: None,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum BlockType {
    Paragraph,
    Heading,
    BulletList,
    OrderedList,
    CodeBlock,
    Blockquote,
}

impl Default for BlockType {
    fn default() -> Self {
        BlockType::Paragraph
    }
}

/// Block-level attributes
#[derive(Debug, Clone, Serialize, Deserialize, Default, PartialEq, Eq)]
pub struct BlockAttrs {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub level: Option<u8>, // For headings: 1-6
    #[serde(skip_serializing_if = "Option::is_none")]
    pub language: Option<String>, // For code blocks
}

// -----------------------------------------------------------------------------
// Inline Content
// -----------------------------------------------------------------------------

/// Inline content with optional formatting marks
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq, Default)]
pub struct InlineElement {
    pub inline_type: InlineType,
    pub text: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub marks: Option<Vec<TextMark>>,
}

impl InlineElement {
    /// Creates a new text inline node
    pub fn text(text: impl Into<String>) -> Self {
        InlineElement {
            inline_type: InlineType::Text,
            text: text.into(),
            marks: None,
        }
    }

    /// Creates a new text inline node with formatting marks
    pub fn text_with_marks(text: impl Into<String>, marks: Vec<TextMark>) -> Self {
        InlineElement {
            inline_type: InlineType::Text,
            text: text.into(),
            marks: Some(marks),
        }
    }

    /// Creates a hard break inline node
    pub fn hard_break() -> Self {
        InlineElement {
            inline_type: InlineType::HardBreak,
            text: String::new(),
            marks: None,
        }
    }

    /// Adds a mark to this inline node
    pub fn add_mark(&mut self, mark: TextMark) {
        self.marks.get_or_insert_with(Vec::new).push(mark);
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum InlineType {
    Text,
    HardBreak,
}

impl Default for InlineType {
    fn default() -> Self {
        InlineType::Text
    }
}

// -----------------------------------------------------------------------------
// Text Marks (Formatting)
// -----------------------------------------------------------------------------

/// Formatting mark (bold, italic, link, etc.)
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct TextMark {
    pub mark_type: MarkType,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub attrs: Option<MarkAttrs>,
}

impl TextMark {
    /// Creates a bold mark
    pub fn bold() -> Self {
        TextMark {
            mark_type: MarkType::Bold,
            attrs: None,
        }
    }

    /// Creates an italic mark
    pub fn italic() -> Self {
        TextMark {
            mark_type: MarkType::Italic,
            attrs: None,
        }
    }

    /// Creates an underline mark
    pub fn underline() -> Self {
        TextMark {
            mark_type: MarkType::Underline,
            attrs: None,
        }
    }

    /// Creates a strikethrough mark
    pub fn strikethrough() -> Self {
        TextMark {
            mark_type: MarkType::Strikethrough,
            attrs: None,
        }
    }

    /// Creates a code mark
    pub fn code() -> Self {
        TextMark {
            mark_type: MarkType::Code,
            attrs: None,
        }
    }

    /// Creates a link mark with the given URL
    pub fn link(href: impl Into<String>) -> Self {
        TextMark {
            mark_type: MarkType::Link,
            attrs: Some(MarkAttrs {
                href: Some(href.into()),
            }),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum MarkType {
    Bold,
    Italic,
    Underline,
    Strikethrough,
    Code,
    Link,
}

/// Mark-level attributes
#[derive(Debug, Clone, Serialize, Deserialize, Default, PartialEq, Eq)]
pub struct MarkAttrs {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub href: Option<String>, // For links
}
