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

pub fn part2_smarter(reports: List(List(Int))) {
  reports
  |> list.map(fn(report) {
    case report {
      [first, ..rest] ->
        is_safe(rest) || can_be_safe(rest, first, False, True, True)
      _ -> True
    }
  })
  |> list.count(function.identity)
  |> io.debug
}

pub fn can_be_safe(
  remaining_report: List(Int),
  previous_number: Int,
  skipped: Bool,
  can_be_inc: Bool,
  can_be_dec: Bool,
) -> Bool {
  // io.debug("---")
  // io.debug(remaining_report)
  // io.debug(previous_number)
  // io.debug("skipped: " <> bool.to_string(skipped))
  // io.debug("can_be_inc: " <> bool.to_string(can_be_inc))
  // io.debug("can_be_dec: " <> bool.to_string(can_be_dec))

  case remaining_report {
    [] -> can_be_inc || can_be_dec
    [current_number, ..rest] -> {
      let diff = current_number - previous_number
      let new_can_be_inc = can_be_inc && diff >= 1 && diff <= 3
      let new_can_be_dec = can_be_dec && diff >= -3 && diff <= -1
      case skipped, new_can_be_inc, new_can_be_dec {
        True, False, False -> False
        True, _, _ ->
          can_be_safe(
            rest,
            current_number,
            skipped,
            new_can_be_inc,
            new_can_be_dec,
          )
        False, _, _ -> {
          can_be_safe(
            rest,
            current_number,
            False,
            new_can_be_inc,
            new_can_be_dec,
          )
          || can_be_safe(rest, previous_number, True, can_be_inc, can_be_dec)
        }
      }
    }
  }
}

pub fn main() {
  let reports =
    utils.parse_lines_from_file("input/y2024/d02/input.txt", parse_line)
    |> result.unwrap([])

  reports
  |> part1

  reports
  |> part2

  reports
  |> part2_smarter
}
