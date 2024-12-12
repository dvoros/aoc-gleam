import gleam/int
import gleam/io
import gleam/list
import matrix
import utils

const dirs = [#(0, -1), #(1, 0), #(0, 1), #(-1, 0)]

fn edges(cells: List(#(Int, Int))) {
  cells
  |> list.flat_map(fn(c) {
    dirs
    |> list.filter_map(fn(d) {
      case list.contains(cells, #(c.0 + d.0, c.1 + d.1)) {
        True -> Error(Nil)
        False -> Ok(#(c, d))
      }
    })
  })
}

fn distance(c1: #(Int, Int), c2: #(Int, Int)) {
  int.absolute_value(c1.0 - c2.0) + int.absolute_value(c1.1 - c2.1)
}

fn can_be_grouped(
  e1: #(#(Int, Int), #(Int, Int)),
  e2: #(#(Int, Int), #(Int, Int)),
) {
  distance(e1.0, e2.0) == 1 && e1.1 == e2.1
}

fn perimeter(cells: List(matrix.Cell(a))) -> Int {
  cells
  |> list.map(fn(c) { #(c.row, c.column) })
  |> edges
  |> list.length
}

fn perimeter2(cells: List(matrix.Cell(a))) -> Int {
  cells
  |> list.map(fn(c) { #(c.row, c.column) })
  |> edges
  |> utils.group(can_be_grouped)
  |> list.length
}

fn part1(regions: List(List(matrix.Cell(a)))) {
  regions
  |> list.map(fn(region) { perimeter(region) * list.length(region) })
  |> list.reduce(int.add)
}

fn part2(regions: List(List(matrix.Cell(a)))) {
  regions
  |> list.map(fn(region) { perimeter2(region) * list.length(region) })
  |> list.reduce(int.add)
}

pub fn main() {
  let assert Ok(lines) = utils.read_lines_from_file("input/y2024/d12/input.txt")
  let mx = matrix.new_from_string_list(lines)

  let regions = matrix.flood_all(mx)
  let _ = part1(regions) |> io.debug
  let _ = part2(regions) |> io.debug
}
