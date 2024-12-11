import gleam/int
import gleam/io
import gleam/list
import gleam/string
import utils

fn is_even_digit(number: Int) -> Bool {
  let digits = number |> int.to_string |> string.length
  digits % 2 == 0
}

fn split(number: Int) -> List(Int) {
  let number_str = number |> int.to_string
  let digits = number_str |> string.length
  let half = digits / 2

  [string.slice(number_str, 0, half), string.slice(number_str, half, half)]
  |> list.filter_map(int.parse)
}

fn blink(numbers: List(Int)) -> List(Int) {
  numbers
  |> list.flat_map(fn(n) {
    case n == 0, is_even_digit(n) {
      True, _ -> [1]
      _, True -> split(n)
      _, _ -> [n * 2024]
    }
  })
}

fn repeat(times: Int, func: fn(a) -> a, input: a) {
  io.debug(times)
  case times == 0 {
    True -> input
    False -> repeat(times - 1, func, func(input))
  }
}

pub fn main() {
  let assert Ok(line) =
    utils.read_file_split_by("input/y2024/d11/input.txt", " ")
  let numbers =
    line
    |> list.filter_map(int.parse)

  repeat(25, blink, numbers)
  |> list.length
  |> io.debug
}
