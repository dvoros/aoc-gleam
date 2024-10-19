import gleam/erlang/atom
import gleam/io
import gleam/list
import matrix
import utils

pub fn occupied_around(mx: matrix.Matrix(String), r: Int, c: Int) -> Int {
  matrix.neighbors8(mx, r, c) |> list.count(fn(x) { x == "#" })
}

pub fn do_round(mx: matrix.Matrix(String)) -> matrix.Matrix(String) {
  matrix.map(mx, fn(val, r, c) {
    case val {
      "L" ->
        case occupied_around(mx, r, c) {
          0 -> "#"
          _ -> "L"
        }
      "#" ->
        case occupied_around(mx, r, c) >= 4 {
          True -> "L"
          False -> "#"
        }
      x -> x
    }
  })
}

pub fn do_rounds_until_no_change(
  mx: matrix.Matrix(String),
) -> matrix.Matrix(String) {
  let after_round = do_round(mx)
  case mx == after_round {
    True -> mx
    False -> do_rounds_until_no_change(after_round)
  }
}

pub fn number_of_occupied(mx: matrix.Matrix(String)) -> Int {
  matrix.count(mx, fn(val, _, _) { val == "#" })
}

pub fn main() {
  let assert Ok(lines) = utils.read_lines_from_file("input/d11/input.txt")
  matrix.new_from_string_list(lines)
  |> do_rounds_until_no_change
  |> number_of_occupied
  |> io.debug
}
