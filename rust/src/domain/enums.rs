use mycelium_macros::SurrealDbEnum;

#[repr(u8)]
#[derive(Copy, Clone, Debug, PartialEq, Eq, Hash, SurrealDbEnum)]
pub enum TaskState {
    Todo = 0,
    InProgress = 1,
    Done = 2,
    Blocked = 3,
    Cancelled = 4,
}

#[repr(u8)]
#[derive(Copy, Clone, Debug, PartialEq, Eq, Hash, SurrealDbEnum)]
pub enum HistoryStatus {
    Applied = 0,
    Undone = 1,
}

#[repr(u8)]
#[derive(Copy, Clone, Debug, PartialEq, Eq, Hash, SurrealDbEnum)]
pub enum ShapeType {
    Rectangle = 0,
    Circle = 1,
    Diamond = 2,
    Triangle = 3,
    Star = 4,
    Pill = 5,
}

#[repr(u8)]
#[derive(Copy, Clone, Debug, PartialEq, Eq, Hash, SurrealDbEnum)]
pub enum BrushType {
    Pencil = 0,
    Highlighter = 1,
    Eraser = 2,
    Calligraphy = 3,
}

#[repr(u8)]
#[derive(Copy, Clone, Debug, PartialEq, Eq, Hash, SurrealDbEnum)]
pub enum MediaType {
    Image = 0,
    Video = 1,
    Audio = 2,
    Pdf = 3,
}

#[repr(u8)]
#[derive(Copy, Clone, Debug, PartialEq, Eq, Hash, SurrealDbEnum)]
pub enum EndpointShape {
    None = 0,
    Arrow = 1,
    OpenArrow = 2,
    Circle = 3,
    Diamond = 4,
    Square = 5,
}
