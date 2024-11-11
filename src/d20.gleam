import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/regex
import gleam/result
import gleam/set.{type Set}
import gleam/string
import utils

pub type Rows =
  List(String)

pub type Tile {
  Tile(id: Int, rows: Rows, edges: RowCodes)
}

pub type RowCodes =
  Set(String)

pub fn parse_block(block: String) -> Result(Tile, Nil) {
  let assert Ok(re) = regex.from_string("^Tile ([0-9]+):$")

  let lines =
    block
    |> string.split("\n")

  let assert #(Ok(first), Ok(rest)) = #(list.first(lines), list.rest(lines))
  let assert [match] = regex.scan(re, first)
  let assert [option.Some(tile_id)] = match.submatches
  let assert Ok(tile_id) = int.parse(tile_id)

  let edges = edges(rest)

  Ok(Tile(tile_id, rest, edges))
}

pub fn edges(rows: Rows) -> RowCodes {
  let assert Ok(top) = list.first(rows)
  let assert Ok(bottom) = list.last(rows)

  let assert Ok(left) =
    rows
    |> list.map(fn(s) { string.first(s) |> result.unwrap("") })
    |> list.reduce(string.append)
  let assert Ok(right) =
    rows
    |> list.map(fn(s) { string.last(s) |> result.unwrap("") })
    |> list.reduce(string.append)

  [top, right, bottom, left]
  |> list.flat_map(fn(s) { [s, string.reverse(s)] })
  |> set.from_list
}

pub fn main() {
  let assert Ok(tiles) =
    utils.parse_empty_line_separated_blocks_from_file(
      "input/d20/example.txt",
      parse_block,
    )

  tiles
  |> list.map(fn(t1) {
    #(
      t1.id,
      tiles
        |> list.map(fn(t2) {
          t1.edges
          |> set.intersection(t2.edges)
          |> set.size
        })
        |> list.filter(fn(x) { x == 2 })
        |> list.length,
    )
  })
  |> list.filter_map(fn(x) {
    case x.1 == 2 {
      True -> Ok(x.0)
      _ -> Error(Nil)
    }
  })
  |> list.reduce(int.multiply)
  |> io.debug
}
