import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/regex
import gleam/result
import gleam/set
import gleam/string
import graph
import utils

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

pub fn part1() {
  let graph =
    parse_lines()
    |> list.concat
    |> list.fold(graph.new_graph(), fn(g, x) {
      let #(l, r, _) = x
      graph.add_to_graph(g, r, l, 0)
    })

  graph.reachable_from(graph, "shiny gold")
  |> set.size
  // don't count "shiny gold" itself
  |> int.subtract(1)
  |> io.debug
}

pub fn count_bags(graph: graph.Graph) -> Int {
  count_bags_acc(graph, "shiny gold") - 1
}

pub fn count_bags_acc(graph: graph.Graph, from: String) -> Int {
  graph.get_edges_from(graph, from)
  |> list.map(fn(e) { e.weight * count_bags_acc(graph, e.to) })
  |> list.reduce(int.add)
  |> result.try(fn(x) { Ok(x + 1) })
  |> result.unwrap(1)
}

pub fn part2() {
  let graph =
    parse_lines()
    |> list.concat
    |> list.fold(graph.new_graph(), fn(g, x) {
      let #(l, r, n) = x
      graph.add_to_graph(g, l, r, n)
    })

  count_bags(graph)
  |> io.debug
}

pub fn main() {
  part1()
  part2()
}
