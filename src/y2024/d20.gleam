import gleam/bool
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import matrix.{type Coord, type Matrix}
import utils

const jumps = [#(-2, 0), #(2, 0), #(0, -2), #(0, 2)]

fn path_to_dict(path: List(Coord)) -> dict.Dict(Coord, Int) {
  path
  |> list.index_map(fn(p, idx) { #(p, idx) })
  |> dict.from_list
}

fn find_path(mx: Matrix(String), from: Coord, to: Coord) {
  do_find_path(mx, from, to, [])
  |> list.reverse
}

fn do_find_path(mx: Matrix(String), from: Coord, to: Coord, acc: List(Coord)) {
  use <- bool.guard(when: from == to, return: [to, ..acc])

  let nexts =
    matrix.neighbors4_cells(mx, from)
    |> list.filter(fn(c) {
      let prev = list.first(acc) |> result.unwrap(#(-1, -1))
      let this = matrix.cell_coord(c)

      c.value != "#" && this != prev
    })
    |> list.map(matrix.cell_coord)

  let assert [next] = nexts

  do_find_path(mx, next, to, [from, ..acc])
}

fn cheats(path: dict.Dict(Coord, Int)) {
  path
  |> dict.map_values(fn(c, i) {
    jumps
    |> list.map(fn(jump) {
      let target_coord = matrix.add_coord(c, jump)
      let target_value = dict.get(path, target_coord) |> result.unwrap(-1)

      case target_value > i + 2 {
        True -> target_value - { i + 2 }
        False -> 0
      }
    })
    |> list.filter(fn(v) { v >= 100 })
    |> list.length
  })
  |> dict.fold(0, fn(acc, _, v) { acc + v })
}

pub fn main() {
  let assert Ok(lines) = utils.read_lines_from_file("input/y2024/d20/input.txt")
  let mx = matrix.new_from_string_list(lines)

  let assert Ok(start) =
    mx
    |> matrix.filter(fn(v, _r, _c) { v == "S" })
    |> list.map(matrix.cell_coord)
    |> list.first

  let assert Ok(end) =
    mx
    |> matrix.filter(fn(v, _r, _c) { v == "E" })
    |> list.map(matrix.cell_coord)
    |> list.first

  find_path(mx, start, end)
  |> path_to_dict
  |> cheats
  |> io.debug
}
