import gleam/io
import gleam/list
import matrix.{type Coord, type Matrix}
import utils

pub fn values(mx: Matrix(String)) -> List(String) {
  mx
  |> matrix.get_all_cells
  |> list.map(matrix.cell_value)
  |> list.filter(fn(v) { v != "." })
  |> list.unique
}

pub fn coords_with_value(mx: Matrix(String), val: String) {
  mx
  |> matrix.get_all_cells
  |> list.filter(fn(c) { c.value == val })
  |> list.map(matrix.cell_coord)
}

pub fn p1(mx: Matrix(String), a: Coord, b: Coord) {
  let d = matrix.subtract_coord(b, a)
  [matrix.add_coord(b, d), matrix.subtract_coord(a, d)]
  |> list.filter(fn(c) { matrix.get_by_coord(mx, c) != Error(Nil) })
}

pub fn p2(mx: Matrix(String), a: Coord, b: Coord) {
  let ba = matrix.subtract_coord(b, a)
  let ab = matrix.subtract_coord(a, b)
  list.flatten([
    [a, b],
    matrix.cells_taking_steps(mx, b, ba)
      |> list.map(matrix.cell_coord),
    matrix.cells_taking_steps(mx, a, ab)
      |> list.map(matrix.cell_coord),
  ])
  |> list.filter(fn(c) { matrix.get_by_coord(mx, c) != Error(Nil) })
}

pub fn solve(
  mx: Matrix(String),
  f: fn(Matrix(String), Coord, Coord) -> List(Coord),
) {
  values(mx)
  |> list.flat_map(fn(val) {
    coords_with_value(mx, val)
    |> list.combination_pairs
    |> list.flat_map(fn(x) {
      let #(a, b) = x
      f(mx, a, b)
    })
  })
  |> list.filter(fn(c) { matrix.get_by_coord(mx, c) != Error(Nil) })
  |> list.unique
  |> list.length
  |> io.debug
}

pub fn main() {
  let assert Ok(lines) = utils.read_lines_from_file("input/y2024/d08/input.txt")
  let mx = matrix.new_from_string_list(lines)

  solve(mx, p1)
  solve(mx, p2)
}
