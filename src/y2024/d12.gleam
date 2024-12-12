import gleam/int
import gleam/io
import gleam/list
import gleam/result
import matrix
import utils

fn perimeter(mx: matrix.Matrix(a), cells: List(matrix.Cell(a))) -> Int {
  cells
  |> list.map(fn(c) {
    let neighbors_in_group =
      matrix.neighbors4_cells(mx, #(c.row, c.column))
      |> list.filter(list.contains(cells, _))
      |> list.length

    4 - neighbors_in_group
  })
  |> list.reduce(int.add)
  |> result.unwrap(0)
}

pub fn main() {
  let assert Ok(lines) = utils.read_lines_from_file("input/y2024/d12/input.txt")
  let mx = matrix.new_from_string_list(lines)

  matrix.flood_all(mx)
  |> list.map(fn(region) { perimeter(mx, region) * list.length(region) })
  |> list.reduce(int.add)
  |> io.debug
}
