import gleam/bool
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import utils

type Cache =
  dict.Dict(String, Int)

fn is_possible(target: String, towels: List(String)) -> Bool {
  count_possible(target, towels) > 0
}

fn return_cache(key: String, cache: Cache, result: Int) {
  #(dict.insert(cache, key, result), result)
}

fn count_possible(target: String, towels: List(String)) -> Int {
  do_count_possible(target, towels, "", dict.new()) |> pair.second
}

fn do_count_possible(
  target: String,
  towels: List(String),
  already_have: String,
  cache: Cache,
) -> #(Cache, Int) {
  use <- bool.guard(when: target == already_have, return: #(cache, 1))
  use <- bool.guard(
    when: string.length(target) < string.length(already_have),
    return: #(cache, 0),
  )
  use <- bool.guard(when: !string.starts_with(target, already_have), return: #(
    cache,
    0,
  ))
  let remaining = string.drop_start(target, string.length(already_have))
  use <- bool.guard(when: dict.has_key(cache, remaining), return: #(
    cache,
    dict.get(cache, remaining) |> result.unwrap(0),
  ))

  let #(res_cache, res_cnt) =
    towels
    |> list.fold(#(cache, 0), fn(acc, t) {
      let #(acc_cache, acc_cnt) = acc
      let #(inner_cache, inner_cnt) =
        do_count_possible(target, towels, already_have <> t, acc_cache)
      let cache = dict.merge(acc_cache, inner_cache)
      let cnt = acc_cnt + inner_cnt
      #(cache, cnt)
    })

  return_cache(remaining, res_cache, res_cnt)
}

pub fn part1(towels: List(String), targets: List(String)) {
  targets |> list.filter(is_possible(_, towels)) |> list.length |> io.debug
}

pub fn part2(towels: List(String), targets: List(String)) {
  targets
  |> list.map(count_possible(_, towels))
  |> list.reduce(int.add)
  |> io.debug
}

pub fn main() {
  let assert Ok([towels, targets]) =
    utils.read_file_split_by("input/y2024/d19/input.txt", "\n\n")

  let towels = towels |> string.split(", ")

  let targets = targets |> string.split("\n")

  // TODO: pass cache between targets + don't count twice for part1+part2
  let _ = part1(towels, targets)
  let _ = part2(towels, targets)
}
