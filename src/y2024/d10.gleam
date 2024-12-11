import gleam/int
import gleam/io
import gleam/list
import matrix
import utils

fn part1(paths: List(List(List(matrix.Cell(Int))))) {
  paths
  |> list.map(fn(path) {
    path
    |> list.filter_map(list.first)
    |> list.unique
    |> list.length
  })
  |> list.reduce(int.add)
  |> io.debug
}

fn part2(paths: List(List(List(matrix.Cell(Int))))) {
  paths
  |> list.map(list.length)
  |> list.reduce(int.add)
  |> io.debug
}

pub fn main() {
  let assert Ok(lines) = utils.read_lines_from_file("input/y2024/d10/input.txt")
  let mx =
    matrix.new_from_string_list(lines)
    |> matrix.map(fn(v, _r, _c) {
      let assert Ok(v) = int.parse(v)
      v
    })

  let trailheads =
    mx
    |> matrix.filter(fn(v, _r, _c) { v == 0 })

  let is_allowed = fn(from: matrix.Cell(Int), to: matrix.Cell(Int)) -> Bool {
    to.value == from.value + 1
  }

  let target = fn(c: matrix.Cell(Int)) -> Bool { c.value == 9 }

  let paths =
    trailheads
    |> list.map(fn(trailhead) {
      mx
      |> matrix.find_target4(
        #(trailhead.row, trailhead.column),
        target,
        is_allowed,
      )
    })

  let _ = part1(paths)
  let _ = part2(paths)
}
