import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/pair
import gleam/string
import matrix
import utils

fn empty_after_boxes(
  in_front: List(matrix.Cell(String)),
) -> option.Option(#(Int, Int)) {
  let rest =
    in_front
    |> list.drop_while(fn(c) { c.value == "O" })

  case rest {
    [] -> None
    [first_after, ..] -> {
      case first_after.value {
        "." -> Some(matrix.cell_coord(first_after))
        _ -> None
      }
    }
  }
}

fn apply_move(state: #(matrix.Matrix(String), #(Int, Int)), move: String) {
  let #(mx, pos) = state
  let delta = case move {
    "^" -> #(-1, 0)
    ">" -> #(0, 1)
    "v" -> #(1, 0)
    "<" -> #(0, -1)
    _ -> panic as "unexpected move"
  }
  let new_pos = #(pos.0 + delta.0, pos.1 + delta.1)
  let in_front = matrix.cells_taking_steps(mx, pos, delta)

  case in_front {
    [] -> #(mx, pos)
    [first, ..] -> {
      case first.value {
        "O" -> {
          case empty_after_boxes(in_front) {
            None -> #(mx, pos)
            Some(empty_after) -> {
              let mx =
                mx
                |> matrix.set(new_pos.0, new_pos.1, ".")
                |> matrix.set(empty_after.0, empty_after.1, "O")
              #(mx, new_pos)
            }
          }
        }
        "#" -> #(mx, pos)
        "." -> #(mx, new_pos)
        _ -> panic as "unknown value on map"
      }
    }
  }
}

pub fn gps_sum(mx: matrix.Matrix(String)) {
  mx
  |> matrix.get_all_cells
  |> list.map(fn(c) {
    case c.value {
      "O" -> c.row * 100 + c.column
      _ -> 0
    }
  })
  |> list.reduce(int.add)
}

pub fn main() {
  let assert Ok([mx, moves]) =
    utils.read_file_split_by("input/y2024/d15/input.txt", "\n\n")

  let mx =
    mx
    |> string.split("\n")
    |> matrix.new_from_string_list

  let assert Ok(start) =
    mx
    |> matrix.filter(fn(v, _r, _c) { v == "@" })
    |> list.map(matrix.cell_coord)
    |> list.first

  let mx =
    mx
    |> matrix.set(start.0, start.1, ".")

  let moves = moves |> string.replace("\n", "")

  moves
  |> string.to_graphemes
  |> list.fold(#(mx, start), fn(state, move) { apply_move(state, move) })
  |> pair.first
  |> gps_sum
  |> io.debug
}
