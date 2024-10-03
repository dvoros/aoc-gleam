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

type Graph =
  dict.Dict(String, List(String))

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
        |> list.flat_map(fn(x) { dict.get(g, x) |> result.unwrap([]) })
        |> set.from_list
      let reachable = set.union(reachable, check_next)
      reachable_from_acc(g, reachable, check_next)
    }
  }
}

pub fn debug_dict(d: Graph) {
  dict.each(d, fn(a, b) { io.println(a <> ": " <> string.join(b, ", ")) })
}

fn parse_lines() -> List(List(#(String, String))) {
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
              let #(_, name) = get_number_and_name(right)
              Ok(#(left, name))
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

fn add_to_graph(map: Graph, left: String, right: String) -> Graph {
  case dict.get(map, right) {
    Ok(v) -> dict.insert(map, right, list.append(v, [left]))
    _ -> dict.insert(map, right, [left])
  }
}

pub fn main() {
  let graph =
    parse_lines()
    |> list.concat
    |> list.fold(dict.new(), fn(g, x) {
      let #(l, r) = x
      add_to_graph(g, l, r)
    })

  reachable_from(graph, "shiny gold")
  |> set.size
  // don't count "shiny gold" itself
  |> int.subtract(1)
  |> io.debug
}
