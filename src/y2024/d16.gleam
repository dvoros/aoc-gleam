import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/order
import matrix.{type Coord, type Matrix}
import utils

type Route =
  List(Coord)

type PosDir {
  PosDir(pos: Coord, dir: Coord)
}

type State {
  State(route: Route, dir: Coord, price: Int)
}

type BestRoutes =
  dict.Dict(PosDir, #(Int, List(Route)))

fn current_posdir(state: State) -> PosDir {
  let assert [pos, ..] = state.route
  PosDir(pos, state.dir)
}

fn left_right(c: Coord) -> List(Coord) {
  [#(-c.1, c.0), #(c.1, -c.0)]
}

fn available_from(mx: Matrix(String), state: State) -> List(State) {
  let assert [pos, ..] = state.route
  let turns =
    left_right(state.dir)
    |> list.map(fn(dir) {
      State(
        [matrix.add_coord(pos, dir), ..state.route],
        dir,
        state.price + 1001,
      )
    })
  [
    State(
      [matrix.add_coord(pos, state.dir), ..state.route],
      state.dir,
      state.price + 1,
    ),
    ..turns
  ]
  |> list.filter(fn(next_state) {
    let assert [next_pos, ..] = next_state.route
    let assert Ok(value) = matrix.get_by_coord(mx, next_pos)
    case value {
      "S" | "." | "E" -> True
      _ -> False
    }
  })
}

fn add_route(best_routes: BestRoutes, from state: State) -> #(Bool, BestRoutes) {
  let posdir = current_posdir(state)
  case dict.get(best_routes, posdir) {
    Error(_) -> #(
      True,
      best_routes
        |> dict.insert(posdir, #(state.price, [state.route])),
    )
    Ok(existing) ->
      case int.compare(state.price, existing.0) {
        order.Gt -> #(False, best_routes)
        order.Eq -> {
          #(
            True,
            best_routes
              |> dict.insert(
                posdir,
                #(state.price, [state.route, ..existing.1]),
              ),
          )
        }
        order.Lt -> {
          #(
            True,
            best_routes
              |> dict.insert(posdir, #(state.price, [state.route])),
          )
        }
      }
  }
}

fn bfs(mx: Matrix(String), from: Coord, dir: Coord) {
  do_bfs(mx, [State([from], dir, 0)], dict.new())
}

fn do_bfs(mx: Matrix(String), to_check: List(State), best_routes: BestRoutes) {
  case to_check {
    [] -> best_routes
    [state, ..rest_to_check] -> {
      let #(changed, best_routes) = add_route(best_routes, state)

      case changed {
        False -> do_bfs(mx, rest_to_check, best_routes)
        True -> {
          let nexts = available_from(mx, state)
          do_bfs(mx, list.append(nexts, rest_to_check), best_routes)
        }
      }
    }
  }
}

pub fn main() {
  let assert Ok(lines) = utils.read_lines_from_file("input/y2024/d16/input.txt")
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

  let paths_to_end =
    bfs(mx, start, #(0, 1))
    |> dict.filter(fn(k, _) { k.pos == end })

  let assert Ok(min_price_to_end) =
    paths_to_end
    |> dict.to_list
    |> list.map(fn(kv) { kv.1.0 })
    |> list.sort(int.compare)
    |> list.first

  let min_paths_to_end =
    paths_to_end
    |> dict.filter(fn(_k, v) { v.0 == min_price_to_end })

  let cells_on_min_paths =
    min_paths_to_end
    |> dict.fold([], fn(acc, _k, v) { list.append(acc, list.concat(v.1)) })
    |> list.unique

  mx
  |> matrix.map_by_coord(fn(val, c) {
    case cells_on_min_paths |> list.contains(c) {
      True -> "O"
      False -> val
    }
  })
  // |> matrix.debug

  io.println("Min price to end: " <> int.to_string(min_price_to_end))
  io.println(
    "# of cells on min paths: "
    <> int.to_string(cells_on_min_paths |> list.length),
  )
}
