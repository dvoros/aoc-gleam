import gleam/dict
import gleam/dynamic.{type Dynamic}
import gleam/list
import gleam/result
import gleam/string

@external(erlang, "file", "read_file")
pub fn read_file(name: String) -> Result(String, Dynamic)

pub fn read_file_split_by(
  name: String,
  separator: String,
) -> Result(List(String), String) {
  let file =
    read_file(name)
    |> result.replace_error("error reading file")

  case file {
    Error(e) -> Error(e)
    Ok(content) -> Ok(string.split(string.trim_right(content), separator))
  }
}

pub fn read_lines_from_file(name: String) -> Result(List(String), String) {
  read_file_split_by(name, "\n")
}

pub fn parse_lines_from_file(
  name: String,
  parser: fn(String) -> Result(t, Nil),
) -> Result(List(t), String) {
  use lines <- result.try(read_lines_from_file(name))
  Ok(lines |> list.filter_map(parser(_)))
}

pub fn parse_empty_line_separated_blocks_from_file(
  name: String,
  parser: fn(String) -> Result(t, Nil),
) {
  use blocks <- result.try(read_file_split_by(name, "\n\n"))
  Ok(blocks |> list.filter_map(parser(_)))
}

pub fn parse_grid_from_file(
  name: String,
) -> dict.Dict(Int, dict.Dict(Int, String)) {
  let assert Ok(lines) = parse_lines_from_file(name, wrap_in_ok(string_to_dict))
  list_to_dict_by_index(lines)
}

pub fn wrap_in_ok(f: fn(a) -> b) -> fn(a) -> Result(b, Nil) {
  fn(x) { Ok(f(x)) }
}

pub fn string_to_dict(str: String) -> dict.Dict(Int, String) {
  list_to_dict_by_index(string.to_graphemes(str))
}

pub fn list_to_dict_by_index(l: List(a)) -> dict.Dict(Int, a) {
  list.index_map(l, fn(x, i) { #(i, x) })
  |> dict.from_list()
}

pub fn list_get_by_index(l: List(a), i: Int) -> Result(a, Nil) {
  list_to_dict_by_index(l)
  |> dict.get(i)
}

pub fn ok_identity(x: a) -> Result(a, Nil) {
  Ok(x)
}

pub fn list_to_indexed_dict(list: List(a)) -> dict.Dict(Int, a) {
  list
  |> list.index_map(fn(item, index) { #(index, item) })
  |> dict.from_list
}

pub fn count_same(numbers: List(a), sorted: List(a)) -> Int {
  do_count_same(numbers, sorted, 0)
}

pub fn do_count_same(numbers: List(a), sorted: List(a), acc: Int) -> Int {
  case numbers, sorted {
    [n, ..nr], [s, ..sr] -> {
      let newacc = case n == s {
        True -> acc + 1
        False -> acc
      }
      do_count_same(nr, sr, newacc)
    }
    _, _ -> acc
  }
}
