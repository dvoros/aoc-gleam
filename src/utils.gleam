import gleam/dynamic.{type Dynamic}
import gleam/list
import gleam/result
import gleam/string

@external(erlang, "file", "read_file")
pub fn read_file(name: String) -> Result(String, Dynamic)

fn read_file_split_by(
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
