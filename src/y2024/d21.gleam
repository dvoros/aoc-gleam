import gleam/bool
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import matrix.{type Coord, type Matrix}
import utils

pub type Path =
  List(String)

pub fn dir_to_string(c: Coord) -> String {
  case c {
    #(-1, 0) -> "^"
    #(1, 0) -> "v"
    #(0, -1) -> "<"
    #(0, 1) -> ">"
    _ -> panic as "unexpected direction"
  }
}

pub fn find_single_value(mx: Matrix(a), val: a) -> Result(Coord, Nil) {
  case
    mx
    |> matrix.filter(fn(v, _r, _c) { v == val })
    |> list.map(matrix.cell_coord)
  {
    [found] -> Ok(found)
    _ -> Error(Nil)
  }
}

fn directions(from: Coord, to: Coord) {
  let diff = matrix.subtract_coord(to, from)
  let r = diff.0 |> utils.sign
  let c = diff.1 |> utils.sign

  [#(r, 0), #(0, c)]
  |> list.filter(fn(x) { x != #(0, 0) })
}

pub fn paths(mx: Matrix(String), from start: String, to target: String) {
  let assert Ok(start) = find_single_value(mx, start)
  let assert Ok(target) = find_single_value(mx, target)

  let assert Ok(res) = do_paths(mx, start, target)
  res
}

pub fn do_paths(
  mx: Matrix(String),
  from start: Coord,
  to target: Coord,
) -> Result(List(Path), Nil) {
  use <- bool.guard(when: start == target, return: Ok([["A"]]))
  let assert Ok(v) = matrix.get_by_coord(mx, start)
  use <- bool.guard(when: v == "x", return: Error(Nil))

  Ok(
    directions(start, target)
    |> list.flat_map(fn(dir) {
      case do_paths(mx, matrix.add_coord(start, dir), target) {
        Ok(res) -> list.map(res, fn(path) { [dir_to_string(dir), ..path] })
        Error(_) -> []
      }
    }),
  )
}

pub fn sequence(
  mx: Matrix(String),
  start: String,
  seq: List(String),
) -> List(Path) {
  case seq {
    [last] -> paths(mx, start, last)
    [next, ..rest] -> {
      let paths_to_next = paths(mx, start, next)
      let paths_for_rest = sequence(mx, next, rest)

      paths_to_next
      |> list.flat_map(fn(path_to_next) {
        paths_for_rest
        |> list.map(fn(path_for_rest) {
          list.append(path_to_next, path_for_rest)
        })
      })
    }
    _ -> panic as "shouldn't get here"
  }
}

fn complexity(
  numpad: Matrix(String),
  dirpad: Matrix(String),
  code: String,
  cache: dict.Dict(#(String, String, Int), Int),
  depth: Int,
) {
  let assert Ok(shortest) =
    sequence(numpad, "A", code |> string.to_graphemes)
    |> list.map(fn(seq) {
      let assert Ok(res) =
        ["A", ..seq]
        |> list.window_by_2
        |> list.map(fn(window) {
          let #(from, to) = window
          min_presses_for(dirpad, from, to, depth, cache)
        })
        |> list.reduce(int.add)

      res
    })
    |> list.reduce(int.min)

  let assert Ok(numeric_part) = code |> string.drop_end(1) |> int.parse

  shortest * numeric_part
}

fn min_presses_for(
  dirpad: Matrix(String),
  from: String,
  to: String,
  at_level: Int,
  cache: dict.Dict(#(String, String, Int), Int),
) {
  use <- bool.guard(when: at_level == 1, return: 1)
  let cached_value = dict.get(cache, #(from, to, at_level))
  use <- bool.guard(
    when: cached_value != Error(Nil),
    return: cached_value |> result.unwrap(0),
  )

  let assert Ok(res) =
    paths(dirpad, from, to)
    |> list.map(fn(path) {
      let assert Ok(res) =
        ["A", ..path]
        |> list.window_by_2
        |> list.map(fn(window) {
          let #(innex_from, inner_to) = window
          min_presses_for(dirpad, innex_from, inner_to, at_level - 1, cache)
        })
        |> list.reduce(int.add)

      res
    })
    |> list.reduce(int.min)

  res
}

fn build_cache(
  dirpad: Matrix(String),
  depth: Int,
) -> dict.Dict(#(String, String, Int), Int) {
  let dirs = ["^", "<", ">", "v", "A"]
  list.range(1, depth)
  |> list.fold(dict.new(), fn(cache, level) {
    dirs
    |> list.fold(cache, fn(cache, from) {
      dirs
      |> list.fold(cache, fn(cache, to) {
        use <- bool.guard(when: from == to, return: cache)
        dict.insert(
          cache,
          #(from, to, level),
          min_presses_for(dirpad, from, to, level, cache),
        )
      })
    })
  })
}

pub fn main() {
  let assert Ok(codes) = utils.read_lines_from_file("input/y2024/d21/input.txt")

  let numpad = matrix.new_from_string_list(["789", "456", "123", "x0A"])

  let dirpad = matrix.new_from_string_list(["x^A", "<v>"])

  let cache = build_cache(dirpad, 26)

  let _ =
    codes
    |> list.map(complexity(numpad, dirpad, _, cache, 3))
    |> list.reduce(int.add)
    |> io.debug

  codes
  |> list.map(complexity(numpad, dirpad, _, cache, 26))
  |> list.reduce(int.add)
  |> io.debug
}
