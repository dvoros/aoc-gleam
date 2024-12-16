import gleam/dict
import gleam/io
import gleam/list
import gleam/option.{type Option}
import matrix.{type Cell, type Coord, type Matrix}
import utils

fn left_right(c: Coord) -> List(Coord) {
  [#(-c.1, c.0), #(c.1, -c.0)]
}

fn available_from(
  from: Coord,
  dir: Coord,
  base_price: Int,
) -> List(#(Coord, Coord, Int)) {
  let nexts =
    left_right(dir)
    |> list.map(fn(dir) {
      #(matrix.add_coord(from, dir), dir, base_price + 1001)
    })
  [#(matrix.add_coord(from, dir), dir, base_price + 1), ..nexts]
}

fn bfs(mx: Matrix(String), from: Coord, dir: Coord) {
  do_bfs(mx, [#(from, dir, 0)], dict.new())
}

fn do_bfs(
  mx: Matrix(String),
  to_check: List(#(Coord, Coord, Int)),
  best_prices: dict.Dict(Coord, Int),
) {
  case to_check {
    [] -> best_prices
    [first, ..rest] -> {
      let #(pos, dir, price) = first
      case dict.get(best_prices, pos) {
        Ok(x) if price >= x -> do_bfs(mx, rest, best_prices)
        _ -> {
          let best_prices = dict.insert(best_prices, pos, price)
          let nexts =
            available_from(pos, dir, price)
            |> list.filter(fn(next) {
              let #(pos, _, price) = next
              case dict.get(best_prices, pos) {
                Ok(x) if price >= x -> False
                _ -> {
                  let assert Ok(value) = matrix.get_by_coord(mx, pos)
                  case value {
                    "S" | "." | "E" -> True
                    _ -> False
                  }
                }
              }
            })
          let to_check = list.append(rest, nexts)

          do_bfs(mx, to_check, best_prices)
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

  // let assert Ok(#(price, route)) = search(mx, start, #(0, 1))

  let bfs_res = bfs(mx, start, #(0, 1)) |> dict.get(end) |> io.debug
}
