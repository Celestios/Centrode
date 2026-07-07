#[derive(Debug, Clone)]
pub struct Variable {
    pub id: usize,
    pub desired_pos: f64,
    pub weight: f64,
    pub final_pos: f64,
    pub min_limit: f64,
    pub max_limit: f64,
}

impl Variable {
    pub fn new(id: usize, desired_pos: f64, weight: f64) -> Self {
        Self {
            id,
            desired_pos,
            weight,
            final_pos: desired_pos,
            min_limit: f64::NEG_INFINITY,
            max_limit: f64::INFINITY,
        }
    }
}

#[derive(Debug, Clone)]
pub struct Constraint {
    pub left_id: usize,
    pub right_id: usize,
    pub gap: f64,
    pub weight: f64,
}

#[derive(Debug, Clone)]
pub struct VpscSolver {
    variables: Vec<Variable>,
    constraints: Vec<Constraint>,
}

impl VpscSolver {
    pub fn new() -> Self {
        Self {
            variables: Vec::new(),
            constraints: Vec::new(),
        }
    }

    pub fn add_variable(&mut self, desired_pos: f64, weight: f64) -> usize {
        let id = self.variables.len();
        self.variables.push(Variable::new(id, desired_pos, weight));
        id
    }

    pub fn add_constraint(&mut self, left_id: usize, right_id: usize, gap: f64, weight: f64) {
        self.constraints.push(Constraint {
            left_id,
            right_id,
            gap,
            weight,
        });
    }

    pub fn solve(&mut self) {
        let n = self.variables.len();
        if n == 0 {
            return;
        }

        for v in &mut self.variables {
            v.final_pos = v.desired_pos;
        }

        if self.constraints.is_empty() {
            return;
        }

        let sorted = self.sort_constraints_by_distance();

        for _iter in 0..100 {
            let mut max_violation: f64 = 0.0;

            for &idx in &sorted {
                let c = &self.constraints[idx];
                let left_pos = self.variables[c.left_id].final_pos;
                let right_pos = self.variables[c.right_id].final_pos;
                let actual_gap = right_pos - left_pos;

                if actual_gap < c.gap - 1e-10 {
                    let violation = c.gap - actual_gap;
                    max_violation = max_violation.max(violation);

                    let left_weight = self.variables[c.left_id].weight;
                    let right_weight = self.variables[c.right_id].weight;
                    let total_weight = left_weight + right_weight;

                    if total_weight < 1e-10 {
                        continue;
                    }

                    let left_push = violation * right_weight / total_weight;
                    let right_push = violation * left_weight / total_weight;

                    self.variables[c.left_id].final_pos -= left_push;
                    self.variables[c.right_id].final_pos += right_push;
                }
            }

            for v in &mut self.variables {
                if v.final_pos < v.min_limit {
                    v.final_pos = v.min_limit;
                }
                if v.final_pos > v.max_limit {
                    v.final_pos = v.max_limit;
                }
            }

            if max_violation < 1e-10 {
                break;
            }
        }
    }

    fn sort_constraints_by_distance(&self) -> Vec<usize> {
        let mut indexed: Vec<(usize, f64)> = self
            .constraints
            .iter()
            .enumerate()
            .map(|(i, c)| {
                let dist = (self.variables[c.right_id].desired_pos
                    - self.variables[c.left_id].desired_pos)
                    .abs();
                (i, dist)
            })
            .collect();
        indexed.sort_by(|a, b| a.1.total_cmp(&b.1));
        indexed.into_iter().map(|(i, _)| i).collect()
    }

    pub fn get_positions(&self) -> Vec<f64> {
        self.variables.iter().map(|v| v.final_pos).collect()
    }

    pub fn set_variable_limits(&mut self, id: usize, min: f64, max: f64) {
        if let Some(v) = self.variables.get_mut(id) {
            v.min_limit = min;
            v.max_limit = max;
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_no_constraints() {
        let mut solver = VpscSolver::new();
        let _v0 = solver.add_variable(10.0, 1.0);
        let _v1 = solver.add_variable(20.0, 1.0);
        solver.solve();
        let pos = solver.get_positions();
        assert!((pos[0] - 10.0).abs() < 1e-6);
        assert!((pos[1] - 20.0).abs() < 1e-6);
    }

    #[test]
    fn test_two_overlapping_variables() {
        let mut solver = VpscSolver::new();
        let v0 = solver.add_variable(10.0, 1.0);
        let v1 = solver.add_variable(12.0, 1.0);
        solver.add_constraint(v0, v1, 5.0, 1.0);
        solver.solve();
        let pos = solver.get_positions();
        assert!(pos[1] - pos[0] >= 4.99, "gap = {}", pos[1] - pos[0]);
    }

    #[test]
    fn test_three_variables_chain() {
        let mut solver = VpscSolver::new();
        let v0 = solver.add_variable(0.0, 1.0);
        let v1 = solver.add_variable(2.0, 1.0);
        let v2 = solver.add_variable(3.0, 1.0);
        solver.add_constraint(v0, v1, 5.0, 1.0);
        solver.add_constraint(v1, v2, 5.0, 1.0);
        solver.solve();
        let pos = solver.get_positions();
        assert!(pos[1] - pos[0] >= 4.99, "gap01 = {}", pos[1] - pos[0]);
        assert!(pos[2] - pos[1] >= 4.99, "gap12 = {}", pos[2] - pos[1]);
    }

    #[test]
    fn test_respects_limits() {
        let mut solver = VpscSolver::new();
        let v0 = solver.add_variable(10.0, 1.0);
        solver.variables[v0].min_limit = 8.0;
        solver.variables[v0].max_limit = 12.0;
        solver.solve();
        let pos = solver.get_positions();
        assert!(pos[0] >= 7.99);
        assert!(pos[0] <= 12.01);
    }
}
