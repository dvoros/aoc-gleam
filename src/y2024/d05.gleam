import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/result
import gleam/set
import gleam/string
import parser
import utils

fn parse_rule(str: String) -> #(Int, Int) {
  let assert Ok(res) =
    parser.parse_entire(
      str,
      parser.int()
        |> parser.skip(parser.literal("|"))
        |> parser.then(parser.int()),
    )
  res
}

fn middle_of_list(li: List(Int)) -> Int {
  let middle_index = list.length(li) / 2
  utils.list_get_by_index(li, middle_index)
  |> result.unwrap(0)
}

fn sum_middle_elements(updates: List(List(Int))) {
  updates |> list.map(middle_of_list) |> list.reduce(int.add)
}

fn comparator(rules: set.Set(#(Int, Int))) {
  fn(a: Int, b: Int) -> order.Order {
    case set.contains(rules, #(a, b)), set.contains(rules, #(b, a)) {
      True, _ -> order.Lt
      _, True -> order.Gt
      _, _ -> order.Eq
    }
  }
}

pub fn part1(rules: set.Set(#(Int, Int)), updates: List(List(Int))) {
  updates
  |> list.filter(fn(update) { update == list.sort(update, comparator(rules)) })
  |> sum_middle_elements
}

pub fn part2(rules: set.Set(#(Int, Int)), updates: List(List(Int))) {
  updates
  |> list.filter(fn(update) { update != list.sort(update, comparator(rules)) })
  |> list.map(list.sort(_, comparator(rules)))
  |> sum_middle_elements
}

pub fn main() {
  let assert Ok([rules, updates]) =
    utils.read_file_split_by("input/y2024/d05/input.txt", "\n\n")

  let rules =
    rules
    |> string.split("\n")
    |> list.map(parse_rule)
    |> set.from_list

  let updates =
    updates
    |> string.split("\n")
    |> list.map(fn(update) {
      update
      |> string.split(",")
      |> list.filter_map(int.parse)
    })

  let _ = part1(rules, updates) |> io.debug
  let _ = part2(rules, updates) |> io.debug
}
