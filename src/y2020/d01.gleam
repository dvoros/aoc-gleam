import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set
import utils

pub fn part1() {
  let numbers =
    utils.parse_lines_from_file("input/y2020/d01/input.txt", int.parse)
    |> result.unwrap([])
    |> set.from_list

  set.to_list(numbers)
  |> list.each(fn(x) {
    case set.contains(numbers, 2020 - x) {
      True -> io.debug(x * { 2020 - x })
      _ -> 0
    }
  })
}

pub fn part2() {
  let numbers =
    utils.parse_lines_from_file("input/y2020/d01/input.txt", int.parse)
    |> result.unwrap([])
    |> set.from_list

  set.to_list(numbers)
  |> list.each(fn(x) {
    set.to_list(numbers)
    |> list.each(fn(y) {
      case set.contains(numbers, 2020 - x - y) {
        True -> io.debug(x * y * { 2020 - x - y })
        _ -> 0
      }
    })
  })
}

pub fn main() {
  part1()
  part2()
}
