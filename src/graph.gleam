import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set
import gleam/string

pub type Edge {
  Edge(from: String, to: String, weight: Int)
}

pub type Graph {
  Graph(
    nodes: set.Set(String),
    edges_from: dict.Dict(String, List(Edge)),
    edges_to: dict.Dict(String, List(Edge)),
  )
}

pub fn new_graph() {
  Graph(nodes: set.new(), edges_from: dict.new(), edges_to: dict.new())
}

pub fn get_nodes_with_edges_from(graph: Graph, node: String) -> List(String) {
  get_edges_from(graph, node)
  |> list.map(fn(edge: Edge) { edge.to })
}

pub fn get_edges_from(graph: Graph, node: String) -> List(Edge) {
  dict.get(graph.edges_from, node)
  |> result.unwrap([])
}

pub fn get_neighbors_from(graph: Graph, node: String) -> List(String) {
  get_edges_from(graph, node)
  |> list.map(fn(e) { e.to })
}

pub fn reachable_from(g: Graph, start: String) -> set.Set(String) {
  reachable_from_acc(
    g,
    set.from_list([start]),
    set.from_list([start]),
    set.from_list([]),
  )
}

fn reachable_from_acc(
  g: Graph,
  reachable: set.Set(String),
  check: set.Set(String),
  already_checked: set.Set(String),
) -> set.Set(String) {
  case set.is_empty(check) {
    True -> reachable
    False -> {
      let check_next =
        check
        |> set.to_list
        |> list.flat_map(fn(x) { get_nodes_with_edges_from(g, x) })
        |> list.filter(fn(x) { !set.contains(already_checked, x) })
        |> set.from_list
      let reachable = set.union(reachable, check_next)
      let already_checked = set.union(already_checked, check)
      reachable_from_acc(g, reachable, check_next, already_checked)
    }
  }
}

pub fn add_to_graph(
  graph: Graph,
  from: String,
  to: String,
  weight: Int,
) -> Graph {
  let edge = Edge(from, to, weight)
  Graph(
    nodes: graph.nodes |> set.insert(from) |> set.insert(to),
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

pub fn debug_graph(d: Graph) {
  io.debug("from->to")
  dict.each(d.edges_from, fn(a, b) {
    let tos =
      list.map(b, fn(edge) {
        edge.to <> "(" <> edge.weight |> int.to_string <> ")"
      })
    io.println(a <> " -> " <> string.join(tos, ", "))
  })
  io.debug("to->from")
  dict.each(d.edges_to, fn(a, b) {
    let tos =
      list.map(b, fn(edge) {
        edge.from <> "(" <> edge.weight |> int.to_string <> ")"
      })
    io.println(a <> " <- " <> string.join(tos, ", "))
  })

  d
}
