use surrealdb::types::SurrealValue;

#[derive(Debug, Clone, SurrealValue, Default, PartialEq, Eq)]
pub struct Content {
    pub text: String,
    pub blocks: Vec<ContentBlock>,
}

impl Content {
    pub fn new(blocks: Vec<ContentBlock>) -> Self {
        let text = Self::compute_plain_text(&blocks);
        Content { text, blocks }
    }

    pub fn from_plain_text(text: impl Into<String>) -> Self {
        let text = text.into();
        let blocks = if text.is_empty() {
            vec![]
        } else {
            vec![ContentBlock::paragraph(text.clone())]
        };
        Content { text, blocks }
    }

    pub fn to_plain_text(&self) -> String {
        Self::compute_plain_text(&self.blocks)
    }

    fn compute_plain_text(blocks: &[ContentBlock]) -> String {
        let mut result = String::new();
        for block in blocks {
            for inline in &block.content {
                result.push_str(&inline.text);
            }
            result.push('\n');
        }
        if result.ends_with('\n') {
            result.pop();
        }
        result
    }

    pub fn refresh_text(&mut self) {
        self.text = self.to_plain_text();
    }
}

// -----------------------------------------------------------------------------
// Block-Level Content
// -----------------------------------------------------------------------------

#[derive(Debug, Clone, SurrealValue, PartialEq, Eq)]
pub struct ContentBlock {
    pub block_type: BlockType,
    pub content: Vec<InlineElement>,
    pub attrs: Option<BlockAttrs>,
}

impl Default for ContentBlock {
    fn default() -> Self {
        Self::paragraph("")
    }
}

impl ContentBlock {
    pub fn paragraph(text: impl Into<String>) -> Self {
        ContentBlock {
            block_type: BlockType::Paragraph,
            content: vec![InlineElement::text(text)],
            attrs: None,
        }
    }

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

    pub fn bullet_list(text: impl Into<String>) -> Self {
        ContentBlock {
            block_type: BlockType::BulletList,
            content: vec![InlineElement::text(text)],
            attrs: None,
        }
    }

    pub fn ordered_list(text: impl Into<String>) -> Self {
        ContentBlock {
            block_type: BlockType::OrderedList,
            content: vec![InlineElement::text(text)],
            attrs: None,
        }
    }

    pub fn blockquote(text: impl Into<String>) -> Self {
        ContentBlock {
            block_type: BlockType::Blockquote,
            content: vec![InlineElement::text(text)],
            attrs: None,
        }
    }
}

#[derive(Debug, Clone, SurrealValue, PartialEq, Eq)]
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
#[derive(Debug, Clone, SurrealValue, Default, PartialEq, Eq)]
pub struct BlockAttrs {
    pub level: Option<u8>,
    pub language: Option<String>,
}

// -----------------------------------------------------------------------------
// Inline Content
// -----------------------------------------------------------------------------

/// Inline content with optional formatting marks
#[derive(Debug, Clone, SurrealValue, PartialEq, Eq, Default)]
pub struct InlineElement {
    pub inline_type: InlineType,
    pub text: String,
    pub marks: Option<Vec<TextMark>>,
}

impl InlineElement {
    pub fn text(text: impl Into<String>) -> Self {
        InlineElement {
            inline_type: InlineType::Text,
            text: text.into(),
            marks: None,
        }
    }

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

#[derive(Debug, Clone, SurrealValue, PartialEq, Eq)]
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

#[derive(Debug, Clone, SurrealValue, PartialEq, Eq)]
pub struct TextMark {
    pub mark_type: MarkType,
    pub attrs: Option<MarkAttrs>,
}

impl TextMark {
    pub fn bold() -> Self {
        TextMark {
            mark_type: MarkType::Bold,
            attrs: None,
        }
    }

    pub fn italic() -> Self {
        TextMark {
            mark_type: MarkType::Italic,
            attrs: None,
        }
    }

    pub fn underline() -> Self {
        TextMark {
            mark_type: MarkType::Underline,
            attrs: None,
        }
    }

    pub fn strikethrough() -> Self {
        TextMark {
            mark_type: MarkType::Strikethrough,
            attrs: None,
        }
    }

    pub fn code() -> Self {
        TextMark {
            mark_type: MarkType::Code,
            attrs: None,
        }
    }

    pub fn link(href: impl Into<String>) -> Self {
        TextMark {
            mark_type: MarkType::Link,
            attrs: Some(MarkAttrs {
                href: Some(href.into()),
            }),
        }
    }
}

#[derive(Debug, Clone, SurrealValue, PartialEq, Eq)]
pub enum MarkType {
    Bold,
    Italic,
    Underline,
    Strikethrough,
    Code,
    Link,
}

/// Mark-level attributes
#[derive(Debug, Clone, SurrealValue, Default, PartialEq, Eq)]
pub struct MarkAttrs {
    pub href: Option<String>, // For links
}
