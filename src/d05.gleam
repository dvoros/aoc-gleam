import gleam/int
import gleam/io
import gleam/list
import gleam/string
import utils

fn parse_lines() -> List(Int) {
  let assert Ok(lines) =
    utils.parse_lines_from_file("input/d05/input.txt", fn(line) {
      line
      |> string.replace("F", "0")
      |> string.replace("B", "1")
      |> string.replace("L", "0")
      |> string.replace("R", "1")
      |> int.base_parse(2)
    })
  lines
}

pub fn part1() {
  parse_lines() |> list.reduce(int.max) |> io.debug
}

pub fn part2() {
  parse_lines()
  |> list.sort(int.compare)
  |> list.reduce(fn(prev, curr) {
    case curr - prev {
      1 -> curr
      _ -> {
        io.debug(curr - 1)
        curr
      }
    }
  })
}

pub fn main() {
  part2()
}
