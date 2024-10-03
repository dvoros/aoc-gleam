import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/regex
import gleam/result
import gleam/set
import gleam/string
import utils

pub type Edge {
  Edge(from: String, to: String, weight: Int)
}

pub type Graph {
  Graph(
    edges_from: dict.Dict(String, List(Edge)),
    edges_to: dict.Dict(String, List(Edge)),
  )
}

pub fn new_graph() {
  Graph(edges_from: dict.new(), edges_to: dict.new())
}

pub fn get_nodes_with_edges_from(graph: Graph, node: String) -> List(String) {
  dict.get(graph.edges_from, node)
  |> result.unwrap([])
  |> list.map(fn(edge: Edge) { edge.to })
}

pub fn reachable_from(g: Graph, start: String) -> set.Set(String) {
  reachable_from_acc(g, set.from_list([start]), set.from_list([start]))
}

fn reachable_from_acc(
  g: Graph,
  reachable: set.Set(String),
  check: set.Set(String),
) -> set.Set(String) {
  case set.is_empty(check) {
    True -> reachable
    False -> {
      let check_next =
        check
        |> set.to_list
        |> list.flat_map(fn(x) { get_nodes_with_edges_from(g, x) })
        |> set.from_list
      let reachable = set.union(reachable, check_next)
      reachable_from_acc(g, reachable, check_next)
    }
  }
}

pub fn debug_graph(d: Graph) {
  io.debug("from->to")
  dict.each(d.edges_from, fn(a, b) {
    let tos = list.map(b, fn(edge) { edge.to })
    io.println(a <> ": " <> string.join(tos, ", "))
  })
  io.debug("to->from")
  dict.each(d.edges_to, fn(a, b) {
    let tos = list.map(b, fn(edge) { edge.to })
    io.println(a <> ": " <> string.join(tos, ", "))
  })
}

fn parse_lines() -> List(List(#(String, String, Int))) {
  let assert Ok(re) = regex.from_string("^(.*) bags contain (.*).$")
  let assert Ok(lines) =
    utils.parse_lines_from_file("input/d07/input.txt", fn(line) {
      let assert [match] = regex.scan(re, line)
      let assert [option.Some(left), option.Some(right)] = match.submatches

      Ok(
        right
        |> string.split(", ")
        |> list.filter_map(fn(right) {
          case right {
            "no other bags" -> Error(Nil)
            right -> {
              let #(number, name) = get_number_and_name(right)
              Ok(#(left, name, number))
            }
          }
        }),
      )
    })
  lines
}

fn get_number_and_name(str: String) -> #(Int, String) {
  let assert Ok(#(number, bag)) = str |> string.split_once(" ")
  #(number |> int.parse |> result.unwrap(0), case string.ends_with(bag, "bag") {
    True -> string.drop_right(bag, 4)
    False -> string.drop_right(bag, 5)
  })
}

fn add_to_graph(graph: Graph, from: String, to: String, weight: Int) -> Graph {
  let edge = Edge(from, to, weight)
  Graph(
    edges_from: case dict.get(graph.edges_from, from) {
      Ok(v) -> dict.insert(graph.edges_from, from, list.append(v, [edge]))
      _ -> dict.insert(graph.edges_from, from, [edge])
    },
    edges_to: case dict.get(graph.edges_to, to) {
      Ok(v) -> dict.insert(graph.edges_to, to, list.append(v, [edge]))
      _ -> dict.insert(graph.edges_to, to, [edge])
    },
  )
}

pub fn part1() {
  let graph =
    parse_lines()
    |> list.concat
    |> list.fold(new_graph(), fn(g, x) {
      let #(l, r, _) = x
      add_to_graph(g, r, l, 0)
    })

  reachable_from(graph, "shiny gold")
  |> set.size
  // don't count "shiny gold" itself
  |> int.subtract(1)
  |> io.debug
}

// pub fn part2() {
//   let graph =
//     parse_lines()
//     |> list.concat
//     |> list.fold(dict.new(), fn(g, x) {
//       let #(l, r, _) = x
//       add_to_graph(g, r, l)
//     })

//   reachable_from(graph, "shiny gold")
//   |> set.size
//   // don't count "shiny gold" itself
//   |> int.subtract(1)
//   |> io.debug
// }

pub fn main() {
  part1()
}
