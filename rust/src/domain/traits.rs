use crate::domain::id::TypedRecordId;
use uuid::Uuid;

#[repr(u8)]
#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
pub enum TableKind {
    INode = 0,
    TaskNode = 1,
    InterNode = 2,
    CommentNode = 3,
    DrawingNode = 4,
    ShapeNode = 5,
    FrameNode = 6,
    MediaNode = 7,
    IRelation = 8,
    Tag = 9,
    MapTheme = 10,
    MapData = 11,
    History = 12,
    Template = 13,
}

#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
pub enum TableCategory {
    Node,
    Relation,
    Auxiliary,
}

impl TableKind {
    #[inline]
    pub const fn table_name(self) -> &'static str {
        match self {
            Self::INode => "INode",
            Self::TaskNode => "TaskNode",
            Self::InterNode => "InterNode",
            Self::CommentNode => "CommentNode",
            Self::DrawingNode => "DrawingNode",
            Self::ShapeNode => "ShapeNode",
            Self::FrameNode => "FrameNode",
            Self::MediaNode => "MediaNode",
            Self::IRelation => "IRelation",
            Self::Tag => "Tag",
            Self::MapTheme => "MapTheme",
            Self::MapData => "MapData",
            Self::History => "History",
            Self::Template => "Template",
        }
    }

    #[inline]
    pub const fn category(self) -> TableCategory {
        match self {
            Self::INode
            | Self::TaskNode
            | Self::InterNode
            | Self::CommentNode
            | Self::DrawingNode
            | Self::ShapeNode
            | Self::FrameNode
            | Self::MediaNode => TableCategory::Node,
            Self::IRelation => TableCategory::Relation,
            Self::Tag | Self::MapTheme | Self::MapData | Self::History | Self::Template => {
                TableCategory::Auxiliary
            }
        }
    }

    pub fn from_table_name(table: &str) -> Result<Self, anyhow::Error> {
        match table {
            "INode" => Ok(Self::INode),
            "TaskNode" => Ok(Self::TaskNode),
            "InterNode" => Ok(Self::InterNode),
            "CommentNode" => Ok(Self::CommentNode),
            "DrawingNode" => Ok(Self::DrawingNode),
            "ShapeNode" => Ok(Self::ShapeNode),
            "FrameNode" => Ok(Self::FrameNode),
            "MediaNode" => Ok(Self::MediaNode),
            "IRelation" => Ok(Self::IRelation),
            "Tag" => Ok(Self::Tag),
            "MapTheme" => Ok(Self::MapTheme),
            "MapData" => Ok(Self::MapData),
            "History" => Ok(Self::History),
            "Template" => Ok(Self::Template),
            other => Err(anyhow::anyhow!("Unknown table name: {}", other)),
        }
    }
}

impl std::str::FromStr for TableKind {
    type Err = anyhow::Error;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        Self::from_table_name(s)
    }
}

impl TryFrom<u8> for TableKind {
    type Error = anyhow::Error;

    fn try_from(value: u8) -> Result<Self, Self::Error> {
        match value {
            0 => Ok(Self::INode),
            1 => Ok(Self::TaskNode),
            2 => Ok(Self::InterNode),
            3 => Ok(Self::CommentNode),
            4 => Ok(Self::DrawingNode),
            5 => Ok(Self::ShapeNode),
            6 => Ok(Self::FrameNode),
            7 => Ok(Self::MediaNode),
            8 => Ok(Self::IRelation),
            9 => Ok(Self::Tag),
            10 => Ok(Self::MapTheme),
            11 => Ok(Self::MapData),
            12 => Ok(Self::History),
            13 => Ok(Self::Template),
            other => Err(anyhow::anyhow!("Invalid TableKind u8 discriminant: {}", other)),
        }
    }
}

pub trait SurrealDbEnum: Sized + Copy {
    fn to_surreal_str(&self) -> &'static str;
    fn from_surreal_bytes(bytes: &[u8]) -> Result<Self, anyhow::Error>;
}

/// Base trait implemented by ALL database structs in Mycelium.
pub trait SurrealTable {
    const KIND: TableKind;
    const FETCH_FIELDS: &'static [&'static str] = &[];

    fn get_key(&self) -> &Uuid;

    fn get_record_id(&self) -> TypedRecordId {
        TypedRecordId::new(Self::KIND, *self.get_key())
    }
}

/// Marker trait implemented by all canvas node structs.
pub trait NodeEntity: SurrealTable {}

/// Marker trait implemented by relation edge structs.
pub trait RelationEntity: SurrealTable {}

/// Marker trait implemented by non-graph workspace & system structs.
pub trait AuxiliaryEntity: SurrealTable {}
