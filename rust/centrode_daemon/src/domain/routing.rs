use std::ops::{Add, Mul, Sub};
use surrealdb::types::SurrealValue;

#[derive(Clone, Copy, Debug, PartialEq, SurrealValue)]
pub struct Point {
    pub x: f64,
    pub y: f64,
}

impl Point {
    pub fn new(x: f64, y: f64) -> Self {
        Self { x, y }
    }

    pub fn distance_to(self, other: Point) -> f64 {
        let dx = self.x - other.x;
        let dy = self.y - other.y;
        (dx * dx + dy * dy).sqrt()
    }

    pub fn lerp(self, other: Point, t: f64) -> Point {
        Point::new(self.x + (other.x - self.x) * t, self.y + (other.y - self.y) * t)
    }

    pub fn length(self) -> f64 {
        (self.x * self.x + self.y * self.y).sqrt()
    }

    pub fn normalize(self) -> Self {
        let len = self.length();
        if len == 0.0 {
            Self::new(0.0, 0.0)
        } else {
            Self::new(self.x / len, self.y / len)
        }
    }
}

impl Add for Point {
    type Output = Self;
    fn add(self, rhs: Self) -> Self::Output {
        Point::new(self.x + rhs.x, self.y + rhs.y)
    }
}

impl Sub for Point {
    type Output = Self;
    fn sub(self, rhs: Self) -> Self::Output {
        Point::new(self.x - rhs.x, self.y - rhs.y)
    }
}

impl Mul<f64> for Point {
    type Output = Self;
    fn mul(self, rhs: f64) -> Self::Output {
        Point::new(self.x * rhs, self.y * rhs)
    }
}

#[derive(Clone, Debug, PartialEq, SurrealValue)]
pub enum RoutingMode {
    Polyline,
    BSpline,
    Orthogonal,
    Octilinear,
    Bezier {
        control_point_1: Option<Point>,
        control_point_2: Option<Point>,
    },
    SineWave {
        control_point_1: Option<Point>,
        control_point_2: Option<Point>,
    },
}
