import gleam/bool
import gleam/io
import gleam/list
import matrix.{type Coord}
import utils

type State {
  State(pos: Coord, dir: Coord)
}

fn patrol_route(
  mx: matrix.Matrix(String),
  from: State,
) -> Result(List(State), String) {
  do_patrol_route(mx, from, [])
}

fn do_patrol_route(
  mx: matrix.Matrix(String),
  from: State,
  acc: List(State),
) -> Result(List(State), String) {
  let from_cell = matrix.get_by_coord(mx, from.pos)
  case from_cell {
    Error(_) -> Ok(acc)
    Ok(_) -> {
      use <- bool.guard(
        when: list.contains(acc, from),
        return: Error("infinite loop"),
      )
      let next_coord_ahead = matrix.add_coord(from.pos, from.dir)
      let next = matrix.get_by_coord(mx, next_coord_ahead)
      case next {
        Ok("#") ->
          do_patrol_route(
            mx,
            State(from.pos, matrix.rotate_coord_right(from.dir)),
            acc,
          )
        _ ->
          do_patrol_route(mx, State(next_coord_ahead, from.dir), [from, ..acc])
      }
    }
  }
}

fn part1(mx: matrix.Matrix(String), from: State) {
  let assert Ok(res) = patrol_route(mx, from)
  res
  |> list.map(fn(s) { s.pos })
  |> list.unique
  |> list.length
  |> io.debug
}

fn part2(mx: matrix.Matrix(String), from: State) {
  let assert Ok(res) = patrol_route(mx, from)

  res
  |> list.map(fn(s) { s.pos })
  |> list.unique
  |> list.reverse
  |> list.drop(1)
  |> list.filter(fn(s) {
    case patrol_route(matrix.set_by_coord(mx, s, "#"), from) {
      Ok(_) -> False
      Error(_) -> True
    }
  })
  |> list.length
  |> io.debug
}

pub fn main() {
  let assert Ok(lines) = utils.read_lines_from_file("input/y2024/d06/input.txt")
  let mx = matrix.new_from_string_list(lines)

  let assert [start] = mx |> matrix.filter(fn(v, _r, _c) { v == "^" })

  let starting_state = State(#(start.row, start.column), #(-1, 0))

  let _ = part1(mx, starting_state)
  // TODO: use sets instead of lists for checking if already visited
  let _ = part2(mx, starting_state)
}
