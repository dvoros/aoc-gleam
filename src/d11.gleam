import gleam/io
import gleam/list
import matrix
import utils

pub fn occupied_around(mx: matrix.Matrix(String), r: Int, c: Int) -> Int {
  matrix.neighbors8(mx, r, c) |> list.count(fn(x) { x == "#" })
}

pub fn do_round_part1(mx: matrix.Matrix(String)) -> matrix.Matrix(String) {
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

pub fn do_round_part2(mx: matrix.Matrix(String)) -> matrix.Matrix(String) {
  matrix.map(mx, fn(val, r, c) {
    case val {
      "L" ->
        case occupied_looking_around(mx, r, c) {
          0 -> "#"
          _ -> "L"
        }
      "#" ->
        case occupied_looking_around(mx, r, c) >= 5 {
          True -> "L"
          False -> "#"
        }
      x -> x
    }
  })
}

pub fn do_rounds_until_no_change(
  mx: matrix.Matrix(String),
  round_fun: fn(matrix.Matrix(String)) -> matrix.Matrix(String),
) -> matrix.Matrix(String) {
  let after_round = round_fun(mx)
  case mx == after_round {
    True -> mx
    False -> do_rounds_until_no_change(after_round, round_fun)
  }
}

pub fn number_of_occupied(mx: matrix.Matrix(String)) -> Int {
  matrix.count(mx, fn(val, _, _) { val == "#" })
}

pub fn occupied_looking_around(mx: matrix.Matrix(String), r: Int, c: Int) -> Int {
  first_visibles_in_8_directions(mx, #(r, c))
  |> list.count(fn(c) { c.value == "#" })
}

pub fn first_visibles_in_8_directions(
  mx: matrix.Matrix(String),
  from: #(Int, Int),
) -> List(matrix.Cell(String)) {
  matrix.coords_8neighbors
  |> list.filter_map(fn(step) {
    matrix.cells_taking_steps(mx, from, step)
    |> list.find(fn(cell) {
      case cell.value {
        "L" | "#" -> True
        _ -> False
      }
    })
  })
}

pub fn part1() {
  let assert Ok(lines) = utils.read_lines_from_file("input/d11/input.txt")
  matrix.new_from_string_list(lines)
  |> do_rounds_until_no_change(do_round_part1)
  |> number_of_occupied
  |> io.debug
}

pub fn main() {
  let assert Ok(lines) = utils.read_lines_from_file("input/d11/input.txt")
  matrix.new_from_string_list(lines)
  |> do_rounds_until_no_change(do_round_part2)
  |> number_of_occupied
  |> io.debug
}
