import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import utils

pub fn part1() {
  let size = 25
  utils.parse_lines_from_file("input/d09/input.txt", int.parse)
  |> result.unwrap([])
  |> list.window(size + 1)
  |> list.map(fn(x) {
    let rev_x = list.reverse(x)
    let target = list.first(rev_x) |> result.unwrap(-1)
    let rev_x_remaining = list.drop(rev_x, 1)
    let valid =
      rev_x_remaining
      |> list.any(fn(n) {
        case n * 2 == target {
          True -> False
          False ->
            rev_x_remaining
            |> list.contains(target - n)
        }
      })
    #(valid, target)
  })
  |> list.filter(fn(x) { !x.0 })
  |> list.first()
  |> result.unwrap(#(False, 0))
  |> pair.second()
}

pub fn part2(p1_res: Int) {
  let numbers =
    utils.parse_lines_from_file("input/d09/input.txt", int.parse)
    |> result.unwrap([])

  let count = list.length(numbers)

  let assert Ok(#(from, to, _)) =
    list.range(0, count - 2)
    |> list.flat_map(fn(from) {
      list.range(from + 2, count)
      |> list.map(fn(to) { #(from, to, range_sum(numbers, from, to)) })
    })
    |> list.filter(fn(x) { x.2 == p1_res })
    |> list.first

  let resulting_range = range(numbers, from, to) |> list.sort(int.compare)
  let assert Ok(first) = resulting_range |> list.first
  let assert Ok(last) = resulting_range |> list.last
  first + last
}

pub fn between(n: Int, lower: Int, upper: Int) -> Bool {
  case n >= lower, n < upper {
    True, True -> True
    _, _ -> False
  }
}

pub fn range(lst: List(a), from: Int, to: Int) -> List(a) {
  lst
  |> list.index_map(fn(n, i) { #(between(i, from, to), n) })
  |> list.filter_map(fn(x) {
    case x.0 {
      True -> Ok(x.1)
      _ -> Error(Nil)
    }
  })
}

pub fn range_sum(numbers: List(Int), from: Int, to: Int) -> Int {
  let assert Ok(res) =
    numbers
    |> list.index_map(fn(n, i) {
      case between(i, from, to) {
        True -> n
        False -> 0
      }
    })
    |> list.reduce(int.add)
  res
}

pub fn main() {
  let p1_res = part1() |> io.debug
  part2(p1_res) |> io.debug
}
