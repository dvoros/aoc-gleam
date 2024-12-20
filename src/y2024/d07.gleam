import gleam/int
import gleam/io
import gleam/list
import gleam/string
import utils

fn concat(a: Int, b: Int) -> Int {
  let assert Ok(res) = int.parse(int.to_string(a) <> int.to_string(b))
  res
}

fn p1(a: Int, b: Int) {
  [a + b, a * b]
}

fn p2(a: Int, b: Int) {
  [concat(a, b), ..p1(a, b)]
}

fn do_solve_with(numbers: List(Int), combinator: fn(Int, Int) -> List(Int)) {
  case numbers {
    [n] -> [n]
    [n, ..rest] -> {
      do_solve_with(rest, combinator)
      |> list.flat_map(fn(sol) { combinator(sol, n) })
    }
    _ -> panic as "shouldn't get here"
  }
}

fn solve_with(
  lines: List(#(Int, List(Int))),
  combinator: fn(Int, Int) -> List(Int),
) {
  lines
  |> list.filter_map(fn(line) {
    let num_of_sol =
      do_solve_with(line.1 |> list.reverse, combinator)
      |> list.count(fn(x) { x == line.0 })
    case num_of_sol > 0 {
      True -> Ok(line.0)
      False -> Error(Nil)
    }
  })
  |> list.reduce(int.add)
  |> io.debug
}

pub fn main() {
  let assert Ok(lines) =
    utils.parse_lines_from_file("input/y2024/d07/input.txt", fn(line: String) {
      let assert Ok(#(target, numbers)) = string.split_once(line, ": ")
      let assert Ok(target) = target |> int.parse
      let numbers = numbers |> string.split(" ") |> list.filter_map(int.parse)
      Ok(#(target, numbers))
    })

  let _ = lines |> solve_with(p1)
  lines |> solve_with(p2)
}
