use crate::relation_engine::geometry::Point;

pub fn orthogonalize_path(
    path: &[Point],
    start_dir: Option<(i32, i32)>,
    end_dir: Option<(i32, i32)>,
    has_start_stub: bool,
    has_end_stub: bool,
) -> Vec<Point> {
    if path.len() < 2 {
        return path.to_vec();
    }
    let mut result = Vec::new();
    result.push(path[0]);

    for i in 0..path.len() - 1 {
        let a = path[i];
        let b = path[i + 1];
        let dx = b.x - a.x;
        let dy = b.y - a.y;

        if dx.abs() < 1e-6 || dy.abs() < 1e-6 {
            result.push(b);
        } else {
            let horizontal_first = if has_start_stub && i == 0 {
                if path.len() >= 3 {
                    let next_pt = path[2];
                    let dx_next = next_pt.x - b.x;
                    let dy_next = next_pt.y - b.y;
                    if dy_next.abs() > dx_next.abs() {
                        true
                    } else {
                        false
                    }
                } else {
                    if let Some((sdx, sdy)) = start_dir {
                        sdx.abs() > sdy.abs()
                    } else {
                        true
                    }
                }
            } else if has_end_stub && i == path.len() - 2 {
                if path.len() >= 3 {
                    let prev_pt = path[path.len() - 3];
                    let dx_prev = a.x - prev_pt.x;
                    let dy_prev = a.y - prev_pt.y;
                    if dy_prev.abs() > dx_prev.abs() {
                        false
                    } else {
                        true
                    }
                } else {
                    if let Some((edx, edy)) = end_dir {
                        edx.abs() <= edy.abs()
                    } else {
                        true
                    }
                }
            } else {
                true
            };
            if horizontal_first {
                result.push(Point::new(b.x, a.y));
            } else {
                result.push(Point::new(a.x, b.y));
            }
            result.push(b);
        }
    }
    result
}

fn push_orthogonal(result: &mut Vec<Point>, pt: Point) {
    let len = result.len();
    if len < 2 {
        result.push(pt);
        return;
    }

    let last = result[len - 1];
    if (pt.x - last.x).abs() < 1e-6 && (pt.y - last.y).abs() < 1e-6 {
        return;
    }

    let prev = result[len - 2];
    let dx1 = last.x - prev.x;
    let dy1 = last.y - prev.y;
    let dx2 = pt.x - last.x;
    let dy2 = pt.y - last.y;

    let cross = dx1 * dy2 - dy1 * dx2;
    if cross.abs() < 1e-6 {
        result[len - 1] = pt;
    } else {
        result.push(pt);
    }
}

fn prune_wiggles_and_push(result: &mut Vec<Point>, mut pt: Point, threshold: f64) {
    if !result.is_empty() {
        let last = *result.last().unwrap();
        if (pt.x - last.x).abs() < 1e-6 && (pt.y - last.y).abs() < 1e-6 {
            return;
        }
    }

    loop {
        if result.len() < 3 {
            push_orthogonal(result, pt);
            break;
        }

        let p_prev = result[result.len() - 3];
        let p_curr = result[result.len() - 2];
        let p_next = result[result.len() - 1];
        let p_nnext = pt;

        let dx1 = p_curr.x - p_prev.x;
        let dy1 = p_curr.y - p_prev.y;
        let dx2 = p_next.x - p_curr.x;
        let dy2 = p_next.y - p_curr.y;
        let dx3 = p_nnext.x - p_next.x;
        let dy3 = p_nnext.y - p_next.y;

        let is_perp12 = (dx1 * dx2 + dy1 * dy2).abs() < 1e-6;
        let is_perp23 = (dx2 * dx3 + dy2 * dy3).abs() < 1e-6;
        let is_para13 = (dx1 * dy3 - dy1 * dx3).abs() < 1e-6;
        let len2 = dx2.hypot(dy2);

        if is_perp12 && is_perp23 && is_para13 && len2 < threshold {
            result.pop();
            result.pop();

            let p_new = if dy1.abs() > dx1.abs() {
                Point::new(p_prev.x, p_nnext.y)
            } else {
                Point::new(p_nnext.x, p_prev.y)
            };

            pt = p_new;
        } else {
            push_orthogonal(result, pt);
            break;
        }
    }
}

pub fn simplify_orthogonal_path(points: &[Point], cell_size: f64) -> Vec<Point> {
    if points.len() <= 2 {
        return points.to_vec();
    }

    let mut result = Vec::with_capacity(points.len());
    let threshold = cell_size + 1.0;

    for &pt in points {
        prune_wiggles_and_push(&mut result, pt, threshold);
    }

    result
}

pub fn octilinearize_path(path: &[Point]) -> Vec<Point> {
    if path.len() < 2 {
        return path.to_vec();
    }
    let mut result = Vec::new();
    result.push(path[0]);
    for i in 0..path.len() - 1 {
        let a = path[i];
        let b = path[i + 1];
        let dx = b.x - a.x;
        let dy = b.y - a.y;
        if dx.abs() < 1e-6 && dy.abs() < 1e-6 {
            continue;
        }
        if dx.abs() < 1e-6 || dy.abs() < 1e-6 || (dx.abs() - dy.abs()).abs() < 1e-6 {
            result.push(b);
        } else {
            let adx = dx.abs();
            let ady = dy.abs();
            if adx > ady {
                let mid_x = a.x + dx.signum() * (adx - ady);
                result.push(Point::new(mid_x, a.y));
            } else {
                let mid_y = a.y + dy.signum() * (ady - adx);
                result.push(Point::new(a.x, mid_y));
            }
            result.push(b);
        }
    }
    result
}

fn prune_octilinear_wiggles_and_push(result: &mut Vec<Point>, pt: Point, threshold: f64) {
    if !result.is_empty() {
        let last = *result.last().unwrap();
        if (pt.x - last.x).abs() < 1e-6 && (pt.y - last.y).abs() < 1e-6 {
            return;
        }
    }

    loop {
        if result.len() < 3 {
            result.push(pt);
            break;
        }

        let p_prev = result[result.len() - 3];
        let p_curr = result[result.len() - 2];
        let p_next = result[result.len() - 1];
        let p_nnext = pt;

        let v1 = p_curr - p_prev;
        let v2 = p_next - p_curr;
        let v3 = p_nnext - p_next;

        let len1 = v1.x.hypot(v1.y);
        let len2 = v2.x.hypot(v2.y);
        let len3 = v3.x.hypot(v3.y);

        if len1 < 1e-6 || len2 < 1e-6 || len3 < 1e-6 {
            result.push(pt);
            break;
        }

        let d1 = Point::new(v1.x / len1, v1.y / len1);
        let d2 = Point::new(v2.x / len2, v2.y / len2);
        let d3 = Point::new(v3.x / len3, v3.y / len3);

        let cross13 = d1.x * d3.y - d1.y * d3.x;
        let dot13 = d1.x * d3.x + d1.y * d3.y;
        let is_parallel13 = cross13.abs() < 1e-5 && dot13 > 0.99;

        let cross12 = d1.x * d2.y - d1.y * d2.x;
        let is_not_parallel12 = cross12.abs() > 1e-5;

        if len2 < threshold {
            if is_parallel13 {
                if is_not_parallel12 {
                    let det = -cross12;
                    if det.abs() > 1e-5 {
                        let dx = p_nnext.x - p_prev.x;
                        let dy = p_nnext.y - p_prev.y;
                        let t = (d2.x * dy - d2.y * dx) / det;
                        let p_new = Point::new(p_prev.x + t * d1.x, p_prev.y + t * d1.y);

                        result.pop();
                        result.pop();
                        result.push(p_new);
                        continue;
                    }
                }
            } else {
                let det = -cross13;
                if det.abs() > 1e-5 {
                    let dx = p_nnext.x - p_prev.x;
                    let dy = p_nnext.y - p_prev.y;
                    let t = (d3.x * dy - d3.y * dx) / det;
                    let p_new = Point::new(p_prev.x + t * d1.x, p_prev.y + t * d1.y);

                    let dist_to_curr = p_new.distance_to(p_curr);
                    if dist_to_curr < 2.0 * threshold {
                        result.pop();
                        result.pop();
                        result.push(p_new);
                        continue;
                    }
                }
            }
        }

        result.push(pt);
        break;
    }
}

pub fn simplify_octilinear_path(path: &[Point], cell_size: f64) -> Vec<Point> {
    if path.len() < 2 {
        return path.to_vec();
    }

    let mut result = Vec::with_capacity(path.len());
    let threshold = cell_size + 1.0;

    for &pt in path {
        prune_octilinear_wiggles_and_push(&mut result, pt, threshold);
    }

    let mut simplified = Vec::new();
    if !result.is_empty() {
        simplified.push(result[0]);
        for i in 1..result.len() - 1 {
            let prev = result[i - 1];
            let curr = result[i];
            let next = result[i + 1];
            let v1 = curr - prev;
            let v2 = next - curr;
            let cross = v1.x * v2.y - v1.y * v2.x;
            if cross.abs() > 1e-6 {
                simplified.push(curr);
            }
        }
        if result.len() > 1 {
            simplified.push(*result.last().unwrap());
        }
    }
    simplified
}
