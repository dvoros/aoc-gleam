import gleam/function
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import utils

pub fn combine(a: #(Int, Int), b: #(Int, Int)) -> #(Int, Int) {
  let n = a.0 * b.0
  let assert [res] =
    list.range(0, n / a.0)
    |> list.filter_map(fn(x) {
      let x = x * a.0 + a.1
      case x % b.0 == b.1 {
        True -> Ok(x)
        False -> Error(Nil)
      }
    })
  #(n, res)
}

pub fn combine_all(numbers: List(#(Int, Int))) -> Int {
  let assert Ok(res) =
    numbers
    |> list.reduce(combine)

  res.1
}

pub fn main() {
  let assert Ok([target, all_buses]) =
    utils.read_file_split_by("input/y2020/d13/input.txt", "\n")

  let target = target |> int.parse |> result.unwrap(0)

  let buses = all_buses |> string.split(",") |> list.filter_map(int.parse)

  let assert Ok(res) =
    buses
    |> list.map(fn(x) { #(x, x - { target % x }) })
    |> list.reduce(fn(acc, x) {
      case x.1 < acc.1 {
        True -> x
        False -> acc
      }
    })

  // part1
  res.0 * res.1
  |> io.debug

  // part2
  all_buses
  |> string.split(",")
  |> list.index_map(fn(bus, idx) {
    case int.parse(bus) {
      Ok(n) -> {
        let remainder = int.modulo(n - idx, n) |> result.unwrap(0)
        Ok(#(n, remainder))
      }
      _ -> Error(Nil)
    }
  })
  |> list.filter_map(function.identity)
  |> combine_all
  |> io.debug
}
