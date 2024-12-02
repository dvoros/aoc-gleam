import gleam/function
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import utils

fn parse_line(line: String) {
  Ok(
    line
    |> string.split(" ")
    |> list.filter_map(int.parse),
  )
}

fn is_safe(report: List(Int)) -> Bool {
  let diffs =
    report
    |> list.window(2)
    |> list.map(fn(window) {
      let assert [a, b] = window
      b - a
    })

  diffs
  |> list.all(fn(diff) { diff >= 1 && diff <= 3 })
  || diffs
  |> list.all(fn(diff) { diff >= -3 && diff <= -1 })
}

pub fn is_safe_removing_one(report: List(Int)) -> Bool {
  report
  |> list.combinations(list.length(report) - 1)
  |> list.any(is_safe)
}

pub fn part1(reports: List(List(Int))) {
  reports
  |> list.map(is_safe)
  |> list.count(function.identity)
  |> io.debug
}

pub fn part2(reports: List(List(Int))) {
  reports
  |> list.map(fn(line) { is_safe(line) || is_safe_removing_one(line) })
  |> list.count(function.identity)
  |> io.debug
}

pub fn main() {
  let reports =
    utils.parse_lines_from_file("input/y2024/d02/input.txt", parse_line)
    |> result.unwrap([])

  reports
  |> part1

  reports
  |> part2
}
