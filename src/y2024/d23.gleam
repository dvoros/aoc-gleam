import gleam/bool
import gleam/dict
import gleam/io
import gleam/list
import gleam/result
import gleam/set.{type Set}
import gleam/string
import graph.{type Graph}
import utils

type UDGraph =
  dict.Dict(String, set.Set(String))

pub fn part1(g: Graph) {
  g.nodes
  |> set.fold(set.new(), fn(acc, node) {
    let neighbors = graph.get_neighbors_from(g, node) |> set.from_list

    neighbors
    |> set.fold(set.new(), fn(acc, n1) -> set.Set(List(String)) {
      let neighbors2 = graph.get_neighbors_from(g, n1) |> set.from_list

      set.intersection(neighbors, neighbors2)
      |> set.map(fn(n2) -> List(String) {
        [node, n1, n2] |> list.sort(string.compare)
      })
      |> set.union(acc)
    })
    |> set.union(acc)
  })
  |> set.filter(fn(s) { s |> list.any(string.starts_with(_, "t")) })
  |> set.size
  |> io.debug
}

pub fn max_set(set1: Set(a), set2: Set(a)) -> Set(a) {
  case set.size(set1) > set.size(set2) {
    True -> set1
    False -> set2
  }
}

pub fn bron_kerbosch(
  g: UDGraph,
  r: Set(String),
  p: Set(String),
  x: Set(String),
  max: Set(String),
) -> Set(String) {
  use <- bool.guard(
    when: set.is_empty(p) && set.is_empty(x),
    return: max_set(r, max),
  )

  set.fold(p, #(p, x, max), fn(acc, v) {
    let #(p, x, max) = acc
    let assert Ok(neighbor_set) = dict.get(g, v)
    let max =
      bron_kerbosch(
        g,
        set.insert(r, v),
        set.intersection(p, neighbor_set),
        set.intersection(x, neighbor_set),
        max,
      )
    #(set.delete(p, v), set.insert(x, v), max)
  }).2
}

pub fn part2(g: UDGraph) {
  let p = dict.keys(g) |> set.from_list
  bron_kerbosch(g, set.new(), p, set.new(), set.new())
  |> set.to_list
  |> list.sort(string.compare)
  |> string.join(",")
  |> io.debug
}

pub fn main() {
  let assert Ok(lines) =
    utils.parse_lines_from_file("input/y2024/d23/input.txt", fn(line: String) {
      string.split_once(line, "-")
    })

  let g =
    lines
    |> list.fold(graph.new_graph(), fn(g, x) {
      let #(l, r) = x
      g
      |> graph.add_to_graph(l, r, 1)
      |> graph.add_to_graph(r, l, 1)
    })

  part1(g)

  let udg =
    lines
    |> list.fold(dict.new(), fn(g, x) {
      let #(l, r) = x
      let g =
        dict.get(g, l)
        |> result.unwrap(set.new())
        |> set.insert(r)
        |> dict.insert(g, l, _)

      dict.get(g, r)
      |> result.unwrap(set.new())
      |> set.insert(l)
      |> dict.insert(g, r, _)
    })

  part2(udg)
}
