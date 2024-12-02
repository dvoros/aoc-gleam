import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/pair
import gleam/result
import gleam/string
import utils

fn parse_line(line: String) {
  case line |> string.split("   ") {
    [a, b] -> {
      case int.parse(a), int.parse(b) {
        Ok(a), Ok(b) -> Ok(#(a, b))
        _, _ -> Error(Nil)
      }
    }
    _ -> Error(Nil)
  }
}

pub fn part1(lists) {
  let sorted_lists =
    lists
    |> pair.map_first(list.sort(_, by: int.compare))
    |> pair.map_second(list.sort(_, by: int.compare))

  list.zip(sorted_lists.0, sorted_lists.1)
  |> list.map(fn(p) {
    let #(a, b) = p
    int.absolute_value(a - b)
  })
  |> list.reduce(int.add)
  |> io.debug
}

pub fn part2(lists) {
  let increment = fn(x) {
    case x {
      Some(i) -> i + 1
      None -> 1
    }
  }

  let #(first, second) =
    lists
    |> pair.map_second(fn(second_list) {
      second_list
      |> list.fold(dict.new(), fn(acc, x) { dict.upsert(acc, x, increment) })
    })

  first
  |> list.map(fn(x) {
    let y = dict.get(second, x) |> result.unwrap(0)
    x * y
  })
  |> list.reduce(int.add)
  |> io.debug
}

pub fn main() {
  let lists =
    utils.parse_lines_from_file("input/y2024/d01/input.txt", parse_line)
    |> result.unwrap([])
    |> list.unzip

  //   part1(lists)
  part2(lists)
}
