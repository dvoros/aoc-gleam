import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/string
import matrix.{type Coord}
import utils

fn find_route(size: Coord, corruptions: List(Coord), bytes: Int) {
  do_find_best_routes(
    size,
    corruptions,
    [#(0, 0)],
    dict.from_list([#(#(0, 0), 0)]),
    bytes,
  )
  // do_find_route(size, corruptions, [#(0, #(0, 0))], set.new(), -1)
}

fn do_find_best_routes(
  size: Coord,
  corruptions: List(Coord),
  to_check: List(Coord),
  best_routes: dict.Dict(Coord, Int),
  bytes: Int,
) {
  case to_check {
    [] -> best_routes
    [from, ..rest] -> {
      let assert Ok(acc) = dict.get(best_routes, from)
      let blocked = list.take(corruptions, bytes)
      let changed_neighbors =
        matrix.neighbors4_coords(from, size)
        |> list.filter(fn(c) { !list.contains(blocked, c) })
        |> list.filter(fn(n) {
          case dict.get(best_routes, n) {
            Error(Nil) -> True
            Ok(best) -> acc + 1 < best
          }
        })

      let new_best_routes =
        changed_neighbors
        |> list.fold(best_routes, fn(best_routes, n) {
          dict.insert(best_routes, n, acc + 1)
        })

      do_find_best_routes(
        size,
        corruptions,
        list.append(rest, changed_neighbors),
        new_best_routes,
        bytes,
      )
    }
  }
}

pub fn part1(size: Coord, corruptions: List(Coord)) {
  find_route(size, corruptions, 1024) |> dict.get(size) |> io.debug
}

pub fn part2(size: Coord, corruptions: List(Coord)) {
  list.range(1025, list.length(corruptions) - 1)
  |> list.map(fn(bytes) {
    io.debug("byte " <> int.to_string(bytes))
    let _ =
      corruptions
      |> list.take(bytes)
      |> list.last
      |> io.debug
    find_route(size, corruptions, bytes) |> dict.get(size) |> io.debug
  })
}

pub fn main() {
  let assert Ok(corruptions) =
    utils.parse_lines_from_file("input/y2024/d18/input.txt", fn(line: String) {
      let assert [x, y] =
        string.split(line, ",")
        |> list.filter_map(int.parse)

      Ok(#(x, y))
    })

  let size = #(70, 70)

  let _ = part1(size, corruptions)

  // TODO: binary search, matrix.flood instead of full BFS...
  let _ = part2(size, corruptions)
}
