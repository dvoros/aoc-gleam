import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
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

fn is_rule_valid(rule: #(Int, Int), update: dict.Dict(Int, Int)) -> Bool {
  case dict.get(update, rule.0), dict.get(update, rule.1) {
    Ok(a), Ok(b) -> a < b
    _, _ -> True
  }
}

fn is_update_valid(
  update: dict.Dict(Int, Int),
  rules: List(#(Int, Int)),
) -> Bool {
  rules
  |> list.all(is_rule_valid(_, update))
}

fn middle(update: dict.Dict(Int, Int)) -> Int {
  let middle_index = dict.size(update) / 2
  let assert [middle] =
    update
    |> dict.filter(fn(_n, i) { i == middle_index })
    |> dict.to_list
    |> list.map(pair.first)
  middle
}

pub fn part1(rules: List(#(Int, Int)), updates: List(dict.Dict(Int, Int))) {
  updates
  |> list.filter(is_update_valid(_, rules))
  |> list.map(middle)
  |> list.reduce(int.add)
}

fn flip_rule_if_wrong(rule: #(Int, Int), update: dict.Dict(Int, Int)) {
  case dict.get(update, rule.0), dict.get(update, rule.1) {
    Ok(a), Ok(b) ->
      case a > b {
        True ->
          update
          |> dict.insert(rule.0, b)
          |> dict.insert(rule.1, a)
        False -> update
      }
    _, _ -> update
  }
}

fn fix_update(
  rules: List(#(Int, Int)),
  update: dict.Dict(Int, Int),
) -> dict.Dict(Int, Int) {
  case is_update_valid(update, rules) {
    True -> update
    False -> {
      let flipped =
        rules
        |> list.fold(update, fn(u, r) { flip_rule_if_wrong(r, u) })
      fix_update(rules, flipped)
    }
  }
}

pub fn part2(rules: List(#(Int, Int)), updates: List(dict.Dict(Int, Int))) {
  updates
  |> list.filter(fn(u) { !is_update_valid(u, rules) })
  |> list.map(fix_update(rules, _))
  |> list.map(middle)
  |> list.reduce(int.add)
}

pub fn main() {
  let assert Ok([rules, updates]) =
    utils.read_file_split_by("input/y2024/d05/input.txt", "\n\n")

  let rules =
    rules
    |> string.split("\n")
    |> list.map(parse_rule)

  let updates =
    updates
    |> string.split("\n")
    |> list.map(fn(update) {
      update
      |> string.split(",")
      |> list.filter_map(int.parse)
      |> list.index_fold(dict.new(), fn(d, n, i) {
        case dict.get(d, n) {
          Ok(_) -> panic as "duplicate page in update"
          _ -> dict.insert(d, n, i)
        }
      })
    })

  let _ = part1(rules, updates) |> io.debug
  let _ = part2(rules, updates) |> io.debug
}
