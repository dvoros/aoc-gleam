import gleam/int
import gleam/io
import gleam/list
import gleam/set
import gleam/string
import utils

pub fn part1() {
  solve(set.union)
}

pub fn part2() {
  solve(set.intersection)
}

pub fn solve(f: fn(set.Set(String), set.Set(String)) -> set.Set(String)) {
  let assert Ok(sets_of_sets) =
    utils.parse_empty_line_separated_blocks_from_file(
      "input/d06/input.txt",
      fn(block) {
        Ok(
          block
          |> string.trim
          |> string.split("\n")
          |> list.map(fn(line) {
            line
            |> string.to_graphemes
            |> list.fold(set.new(), set.insert)
          }),
        )
      },
    )

  sets_of_sets
  |> list.map(fn(sets) {
    let assert Ok(res) =
      sets
      |> list.reduce(f)
    set.size(res)
  })
  |> list.reduce(int.add)
  |> io.debug
}

pub fn main() {
  let _ = part1()
  let _ = part2()
}
