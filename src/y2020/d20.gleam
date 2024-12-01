import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/regex
import gleam/result
import gleam/string
import utils

pub type Rows =
  List(String)

pub type Tile {
  Tile(id: Int, rows: Rows, edges: RowCodes)
}

pub type RowCodes =
  List(String)

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
}

// matching_edge_indices returns the index of the edge of t1 and t2 that match, and a bool
// indicating if the match is in reverse orientation.
pub fn matching_edge_indices(
  t1: Tile,
  t2: Tile,
) -> Result(#(Int, Int, Bool), Nil) {
  t1.edges
  |> list.index_map(fn(e1, i) {
    t2.edges
    |> list.index_map(fn(e2, j) {
      case e1 == e2, e1 == string.reverse(e2) {
        True, _ -> Ok(#(i, j, False))
        _, True -> Ok(#(i, j, True))
        _, _ -> Error(Nil)
      }
    })
  })
  |> list.flatten
  |> list.filter(fn(x) {
    case x {
      Ok(_) -> True
      Error(_) -> False
    }
  })
  |> list.first
  |> result.unwrap(Error(Nil))
}

pub fn shares_edge(t1: Tile, t2: Tile) -> Bool {
  case matching_edge_indices(t1, t2) |> io.debug {
    Ok(_) -> True
    Error(_) -> False
  }
  // t1.edges
  // |> list.flat_map(fn(e1) { [e1, string.reverse(e1)] })
  // |> list.any(fn(e1) { t2.edges |> list.any(fn(e2) { e1 == e2 }) })
}

pub fn main() {
  let assert Ok(tiles) =
    utils.parse_empty_line_separated_blocks_from_file(
      "input/y2020/d20/example.txt",
      parse_block,
    )

  tiles
  |> list.map(fn(t1) {
    #(
      t1.id,
      tiles
        |> list.filter(fn(t2) { t1 != t2 })
        |> list.filter(fn(t2) { shares_edge(t1, t2) })
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
