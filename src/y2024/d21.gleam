import gleam/bool
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
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

type Cache =
  dict.Dict(#(List(String), Int), Int)

fn find_shortest(
  dirpad: Matrix(String),
  seq: List(String),
  depth: Int,
  cache: Cache,
) -> #(Int, Cache) {
  let cache_key = #(seq, depth)
  case dict.get(cache, cache_key) {
    Ok(c) -> #(c, cache)
    Error(_) -> {
      case depth {
        1 -> {
          let res =
            sequence(dirpad, "A", seq)
            |> list.map(list.length)
            |> list.sort(int.compare)
            |> list.first
            |> result.unwrap(-1)
          #(res, dict.insert(cache, cache_key, res))
        }
        _ -> {
          let #(cache, results) =
            sequence(dirpad, "A", seq)
            |> list.map_fold(cache, fn(cache, next_seq) {
              find_shortest(dirpad, next_seq, depth - 1, cache)
              |> pair.swap
            })

          let res =
            results
            |> list.sort(int.compare)
            |> list.first
            |> result.unwrap(-1)

          let cache = dict.insert(cache, cache_key, res)

          #(res, cache)
        }
      }
    }
  }
}

fn complexity(numpad: Matrix(String), dirpad: Matrix(String), code: String) {
  // let assert Ok(shortest) =
  // sequence(numpad, "A", code |> string.to_graphemes)
  // |> list.flat_map(fn(numseq) { sequence(dirpad, "A", numseq) })
  // |> list.flat_map(fn(dirseq) { sequence(dirpad, "A", dirseq) })
  // |> list.map(list.length)
  // |> list.sort(int.compare)
  // |> list.first
  let assert Ok(shortest) =
    sequence(numpad, "A", code |> string.to_graphemes)
    |> list.map_fold(dict.new(), fn(cache, seq) {
      find_shortest(dirpad, seq, 2, cache) |> pair.swap
    })
    |> pair.second
    |> list.sort(int.compare)
    |> list.first

  let assert Ok(numeric_part) = code |> string.drop_end(1) |> int.parse

  shortest * numeric_part
}

pub fn main() {
  let assert Ok(codes) =
    utils.read_lines_from_file("input/y2024/d21/example.txt")

  let numpad =
    matrix.new_from_string_list(["789", "456", "123", "x0A"])
    |> matrix.debug

  let dirpad =
    matrix.new_from_string_list(["x^A", "<v>"])
    |> matrix.debug

  codes
  |> list.map(complexity(numpad, dirpad, _))
  |> list.reduce(int.add)
  |> io.debug
}
