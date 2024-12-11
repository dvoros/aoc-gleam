import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/string
import utils

type Cache =
  dict.Dict(#(Int, Int), Int)

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

fn count(turns: Int, n: Int, c: Cache) -> #(Int, Cache) {
  let res = case turns == 0 {
    True -> #(1, dict.new())
    False -> {
      case dict.get(c, #(turns, n)) {
        Ok(res) -> #(res, dict.new())
        _ -> {
          let res = case n == 0, is_even_digit(n) {
            True, _ -> count(turns - 1, 1, c)
            _, True -> {
              split(n)
              |> list.fold(#(0, dict.new()), fn(acc, n) {
                let res = count(turns - 1, n, dict.merge(c, acc.1))
                #(acc.0 + res.0, dict.merge(acc.1, res.1))
              })
            }
            _, _ -> count(turns - 1, n * 2024, c)
          }
        }
      }
    }
  }
  #(res.0, dict.insert(res.1, #(turns, n), res.0))
}

pub fn main() {
  let assert Ok(line) =
    utils.read_file_split_by("input/y2024/d11/input.txt", " ")
  let numbers =
    line
    |> list.filter_map(int.parse)

  numbers
  |> list.fold(#(0, dict.new()), fn(acc, n) {
    let res = count(75, n, acc.1)
    #(acc.0 + res.0, dict.merge(acc.1, res.1))
  })
  |> pair.first
  |> io.debug
}
