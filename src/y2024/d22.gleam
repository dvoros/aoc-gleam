import gleam/bool
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import utils

fn mix(secret: Int, n: Int) -> Int {
  int.bitwise_exclusive_or(secret, n)
}

fn prune(secret: Int) -> Int {
  secret % 16_777_216
}

fn evolve2000(n: Int) -> Int {
  list.range(1, 2000)
  |> list.fold(n, fn(acc, _) { evolve(acc) })
}

fn evolve(n: Int) -> Int {
  let n =
    mix(n, n * 64)
    |> prune

  let n = mix(n, n / 32)

  mix(n, n * 2048) |> prune
}

fn evolution_sequence(n: Int) {
  do_evolution_sequence(n, 2000, [n])
  |> list.reverse
  |> list.map(fn(x) { x % 10 })
  |> list.window_by_2
  |> list.map(fn(p) { #(p.1, p.1 - p.0) })
}

fn do_evolution_sequence(n: Int, remaining: Int, acc: List(Int)) {
  use <- bool.guard(when: remaining == 0, return: acc)
  let n = evolve(n)
  do_evolution_sequence(n, remaining - 1, [n, ..acc])
}

fn part1(numbers: List(Int)) {
  numbers
  |> list.map(evolve2000)
  |> list.reduce(int.add)
  |> io.debug
}

fn prices(seq: List(#(Int, Int))) -> dict.Dict(List(Int), Int) {
  seq
  |> list.window(4)
  |> list.fold(dict.new(), fn(acc, x) {
    let key = x |> list.map(pair.second)
    let assert Ok(last) = x |> list.last
    let val = last.0
    case dict.has_key(acc, key) {
      True -> acc
      False -> dict.insert(acc, key, val)
    }
  })
}

fn result_of_sequence(prices: List(dict.Dict(List(Int), Int)), seq: List(Int)) {
  prices
  |> list.map(fn(p) { dict.get(p, seq) |> result.unwrap(0) })
  |> list.reduce(int.add)
  |> result.unwrap(0)
}

fn part2(numbers: List(Int)) {
  let prices =
    numbers
    |> list.map(evolution_sequence)
    |> list.map(prices)

  let assert Ok(all_sequences) =
    prices
    |> list.reduce(dict.merge)

  all_sequences
  |> dict.keys
  |> list.fold(0, fn(acc, seq) { int.max(acc, result_of_sequence(prices, seq)) })
  |> io.debug
}

pub fn main() {
  let assert Ok(numbers) =
    utils.parse_lines_from_file("input/y2024/d22/input.txt", int.parse)

  let _ = part1(numbers)
  part2(numbers)
}
