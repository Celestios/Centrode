use surrealdb::types::SurrealValue;
use crate::domain::schema::SurqlSchemaField;

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
                match inline.inline_type {
                    InlineType::Text => result.push_str(&inline.text),
                    InlineType::HardBreak => result.push('\n'),
                }
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
    pub text_align: Option<String>,
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
                ..Default::default()
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
    Highlight,
    TextColor,
    FontFamily,
}

#[derive(Debug, Clone, SurrealValue, Default, PartialEq, Eq)]
pub struct MarkAttrs {
    pub href: Option<String>,
    pub color: Option<u32>,
    pub font_family: Option<String>,
}

impl SurqlSchemaField for Content {
    fn field_type() -> String { "object".to_string() }
    fn sub_field_paths() -> Vec<(String, String)> {
        vec![
            ("text".to_string(), "string".to_string()),
            ("blocks".to_string(), "array".to_string()),
            ("blocks.*".to_string(), "object".to_string()),
            ("blocks.*.block_type".to_string(), "any".to_string()),
            ("blocks.*.content".to_string(), "array".to_string()),
            ("blocks.*.content.*".to_string(), "object".to_string()),
            ("blocks.*.content.*.inline_type".to_string(), "any".to_string()),
            ("blocks.*.content.*.text".to_string(), "string".to_string()),
            ("blocks.*.content.*.marks".to_string(), "option<array>".to_string()),
            ("blocks.*.content.*.marks.*".to_string(), "object".to_string()),
            ("blocks.*.content.*.marks.*.mark_type".to_string(), "any".to_string()),
            ("blocks.*.content.*.marks.*.attrs".to_string(), "option<object>".to_string()),
            ("blocks.*.content.*.marks.*.attrs.href".to_string(), "option<string>".to_string()),
            ("blocks.*.attrs".to_string(), "option<object>".to_string()),
            ("blocks.*.attrs.level".to_string(), "option<int>".to_string()),
            ("blocks.*.attrs.language".to_string(), "option<string>".to_string()),
            ("blocks.*.attrs.text_align".to_string(), "option<string>".to_string()),
        ]
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_content_from_plain_text() {
        // Empty text
        let content_empty = Content::from_plain_text("");
        assert_eq!(content_empty.text, "");
        assert!(content_empty.blocks.is_empty());

        // Single line text
        let content_single = Content::from_plain_text("Hello Mycelium");
        assert_eq!(content_single.text, "Hello Mycelium");
        assert_eq!(content_single.blocks.len(), 1);
        assert_eq!(content_single.blocks[0].block_type, BlockType::Paragraph);
        assert_eq!(content_single.blocks[0].content.len(), 1);
        assert_eq!(content_single.blocks[0].content[0].text, "Hello Mycelium");
    }

    #[test]
    fn test_content_block_constructors() {
        let p_block = ContentBlock::paragraph("Paragraph text");
        assert_eq!(p_block.block_type, BlockType::Paragraph);
        assert_eq!(p_block.content[0].text, "Paragraph text");
        assert!(p_block.attrs.is_none());

        let h_block = ContentBlock::heading("Heading text", 3);
        assert_eq!(h_block.block_type, BlockType::Heading);
        assert_eq!(h_block.content[0].text, "Heading text");
        assert_eq!(h_block.attrs.as_ref().unwrap().level, Some(3));

        let code_block = ContentBlock::code_block("const x = 5;", Some("javascript".to_string()));
        assert_eq!(code_block.block_type, BlockType::CodeBlock);
        assert_eq!(code_block.content[0].text, "const x = 5;");
        assert_eq!(code_block.attrs.as_ref().unwrap().language, Some("javascript".to_string()));

        let bullet = ContentBlock::bullet_list("Bullet item");
        assert_eq!(bullet.block_type, BlockType::BulletList);
        assert_eq!(bullet.content[0].text, "Bullet item");

        let ordered = ContentBlock::ordered_list("Ordered item");
        assert_eq!(ordered.block_type, BlockType::OrderedList);
        assert_eq!(ordered.content[0].text, "Ordered item");

        let quote = ContentBlock::blockquote("Quote item");
        assert_eq!(quote.block_type, BlockType::Blockquote);
        assert_eq!(quote.content[0].text, "Quote item");
    }

    #[test]
    fn test_inline_element_and_marks() {
        let mut inline = InlineElement::text("bold link");
        assert_eq!(inline.inline_type, InlineType::Text);
        assert!(inline.marks.is_none());

        inline.add_mark(TextMark::bold());
        inline.add_mark(TextMark::link("https://mycelium.org"));

        let marks = inline.marks.unwrap();
        assert_eq!(marks.len(), 2);
        assert_eq!(marks[0].mark_type, MarkType::Bold);
        assert_eq!(marks[1].mark_type, MarkType::Link);
        assert_eq!(marks[1].attrs.as_ref().unwrap().href, Some("https://mycelium.org".to_string()));

        let text_with_marks = InlineElement::text_with_marks("italic text", vec![TextMark::italic(), TextMark::underline()]);
        assert_eq!(text_with_marks.marks.as_ref().unwrap().len(), 2);
        assert_eq!(text_with_marks.marks.as_ref().unwrap()[0].mark_type, MarkType::Italic);
        assert_eq!(text_with_marks.marks.as_ref().unwrap()[1].mark_type, MarkType::Underline);

        let hard_break = InlineElement::hard_break();
        assert_eq!(hard_break.inline_type, InlineType::HardBreak);
        assert!(hard_break.text.is_empty());
    }

    #[test]
    fn test_content_plain_text_computation_and_refresh() {
        let blocks = vec![
            ContentBlock {
                block_type: BlockType::Heading,
                content: vec![InlineElement::text("My Document Heading")],
                attrs: Some(BlockAttrs { level: Some(1), language: None }),
            },
            ContentBlock {
                block_type: BlockType::Paragraph,
                content: vec![
                    InlineElement::text("This is "),
                    InlineElement::text_with_marks("formatted", vec![TextMark::bold()]),
                    InlineElement::text(" text."),
                ],
                attrs: None,
            },
        ];

        let mut content = Content::new(blocks);
        // The computed text should join the text of all inline elements in each block, separated by a newline
        assert_eq!(content.text, "My Document Heading\nThis is formatted text.");

        // Modify in-place
        content.blocks[1].content[1].text = "updated bold".to_string();
        content.refresh_text();
        assert_eq!(content.text, "My Document Heading\nThis is updated bold text.");
    }

    #[test]
    fn test_hard_break_plain_text() {
        let blocks = vec![
            ContentBlock {
                block_type: BlockType::Paragraph,
                content: vec![
                    InlineElement::text("Line 1"),
                    InlineElement::hard_break(),
                    InlineElement::text("Line 2"),
                ],
                attrs: None,
            }
        ];
        let content = Content::new(blocks);
        assert_eq!(content.text, "Line 1\nLine 2");
    }
}
