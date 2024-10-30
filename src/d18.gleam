import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import utils

type Operator {
  Add
  Multiply
}

fn parse_line(line: String) -> Result(Int, Nil) {
  let line = line |> string.replace(" ", "")
  let #(result, _) = do_parse_line(line, 0, option.None)
  Ok(result)
}

fn do_operator(
  remaining: String,
  acc: Int,
  n: Int,
  operator: option.Option(Operator),
) -> #(Int, String) {
  case operator {
    option.None -> do_parse_line(remaining, n, option.None)
    option.Some(Add) -> do_parse_line(remaining, acc + n, option.None)
    option.Some(Multiply) -> do_parse_line(remaining, acc * n, option.None)
  }
}

fn do_parse_line(
  line: String,
  acc: Int,
  operator: option.Option(Operator),
) -> #(Int, String) {
  let #(ch, remaining) = string.pop_grapheme(line) |> result.unwrap(#("", ""))
  case ch {
    "" | ")" -> #(acc, remaining)
    "+" -> do_parse_line(remaining, acc, option.Some(Add))
    "*" -> do_parse_line(remaining, acc, option.Some(Multiply))
    "(" -> {
      let #(inside, remaining) = do_parse_line(remaining, 0, option.None)
      do_operator(remaining, acc, inside, operator)
    }
    n -> {
      let assert Ok(n) = int.parse(n)
      do_operator(remaining, acc, n, operator)
    }
  }
}

pub fn main() {
  let assert Ok(results) =
    utils.parse_lines_from_file("input/d18/input.txt", parse_line)

  results |> list.reduce(int.add) |> io.debug
}
