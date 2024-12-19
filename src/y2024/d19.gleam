import gleam/bool
import gleam/dict
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import utils

fn is_possible(target: String, towels: List(String)) -> Bool {
  io.debug(target)
  do_is_possible(target, towels, "", dict.new()) |> pair.second
}

fn return_cache(key: String, cache: dict.Dict(String, Bool), result: Bool) {
  #(dict.insert(cache, key, result), result)
}

fn do_is_possible(
  target: String,
  towels: List(String),
  already_have: String,
  cache: dict.Dict(String, Bool),
) -> #(dict.Dict(String, Bool), Bool) {
  use <- bool.guard(when: target == already_have, return: #(cache, True))
  use <- bool.guard(
    when: string.length(target) < string.length(already_have),
    return: #(cache, False),
  )
  use <- bool.guard(when: !string.starts_with(target, already_have), return: #(
    cache,
    False,
  ))
  let remaining = string.drop_start(target, string.length(already_have))
  use <- bool.guard(when: dict.has_key(cache, remaining), return: #(
    cache,
    dict.get(cache, remaining) |> result.unwrap(False),
  ))

  let #(res_cache, res_ok) =
    towels
    |> list.fold(#(cache, False), fn(acc, t) {
      let #(acc_cache, acc_ok) = acc
      let #(inner_cache, inner_ok) =
        do_is_possible(target, towels, already_have <> t, acc_cache)
      let cache = dict.merge(acc_cache, inner_cache)
      let ok = acc_ok || inner_ok
      #(cache, ok)
    })

  return_cache(remaining, res_cache, res_ok)
}

pub fn main() {
  let assert Ok([towels, targets]) =
    utils.read_file_split_by("input/y2024/d19/input.txt", "\n\n")

  let towels = towels |> string.split(", ")

  let targets = targets |> string.split("\n")

  targets |> list.filter(is_possible(_, towels)) |> list.length |> io.debug
}
