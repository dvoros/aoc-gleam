import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import utils

type Operator {
  OpAdd
  OpMultiply
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
    option.Some(OpAdd) -> do_parse_line(remaining, acc + n, option.None)
    option.Some(OpMultiply) -> do_parse_line(remaining, acc * n, option.None)
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
    "+" -> do_parse_line(remaining, acc, option.Some(OpAdd))
    "*" -> do_parse_line(remaining, acc, option.Some(OpMultiply))
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

fn part1() {
  let assert Ok(results) =
    utils.parse_lines_from_file("input/y2020/d18/input.txt", parse_line)

  results
  |> list.reduce(int.add)
  |> io.debug
}

fn part2() {
  let assert Ok(results) =
    utils.parse_lines_from_file("input/y2020/d18/input.txt", parse_expr)

  results
  |> list.map(eval_expr)
  |> list.reduce(int.add)
  |> io.debug
}

pub fn main() {
  let _ = part1()
  let _ = part2()
}

pub type Expr {
  Number(Int)
  Add(left: Expr, right: Expr)
  Multiply(left: Expr, right: Expr)
}

fn parse_expr(line: String) -> Result(Expr, Nil) {
  let line = line |> string.replace(" ", "")
  let #(expr, remaining) = parse_term(line)
  case remaining {
    "" -> Ok(expr)
    _ -> Error(Nil)
  }
}

// Parse terms (multiplications)
fn parse_term(input: String) -> #(Expr, String) {
  let #(left, remaining) = parse_factor(input)
  parse_term_continuation(left, remaining)
}

fn parse_term_continuation(left: Expr, input: String) -> #(Expr, String) {
  let #(ch, remaining) = string.pop_grapheme(input) |> result.unwrap(#("", ""))
  case ch {
    "*" -> {
      let #(right, remaining) = parse_factor(remaining)
      parse_term_continuation(Multiply(left: left, right: right), remaining)
    }
    _ -> #(left, input)
  }
}

// Parse factors (additions)
fn parse_factor(input: String) -> #(Expr, String) {
  let #(left, remaining) = parse_primary(input)
  parse_factor_continuation(left, remaining)
}

fn parse_factor_continuation(left: Expr, input: String) -> #(Expr, String) {
  let #(ch, remaining) = string.pop_grapheme(input) |> result.unwrap(#("", ""))
  case ch {
    "+" -> {
      let #(right, remaining) = parse_primary(remaining)
      parse_factor_continuation(Add(left: left, right: right), remaining)
    }
    _ -> #(left, input)
  }
}

// Parse primary expressions (numbers and parentheses)
fn parse_primary(input: String) -> #(Expr, String) {
  let #(ch, remaining) = string.pop_grapheme(input) |> result.unwrap(#("", ""))
  case ch {
    "(" -> {
      let #(expr, remaining) = parse_term(remaining)
      let #(close, remaining) =
        string.pop_grapheme(remaining) |> result.unwrap(#("", ""))
      case close {
        ")" -> #(expr, remaining)
        _ -> panic as "Expected closing parenthesis"
      }
    }
    n -> {
      let assert Ok(num) = int.parse(n)
      #(Number(num), remaining)
    }
  }
}

fn eval_expr(expr: Expr) -> Int {
  case expr {
    Number(n) -> n
    Add(left, right) -> eval_expr(left) + eval_expr(right)
    Multiply(left, right) -> eval_expr(left) * eval_expr(right)
  }
}
