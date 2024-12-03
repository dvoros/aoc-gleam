import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import parser
import utils

pub type Token {
  Do
  Dont
  Num(Int)
  Unknown
}

fn do() -> parser.Parser(Token) {
  parser.replace(parser.literal("do()"), Do)
}

fn dont() -> parser.Parser(Token) {
  parser.replace(parser.literal("don't()"), Dont)
}

fn valid_number() -> parser.Parser(Int) {
  parser.between(parser.digit(), 1, 3)
  |> parser.map(string.concat)
  |> parser.map(fn(x) { int.parse(x) |> result.unwrap(0) })
}

fn mul() -> parser.Parser(Token) {
  parser.literal("mul")
  |> parser.skip(parser.literal("("))
  |> parser.proceed(valid_number())
  |> parser.skip(parser.literal(","))
  |> parser.then(valid_number())
  |> parser.skip(parser.literal(")"))
  |> parser.map(fn(x) { Num(x.0 * x.1) })
}

fn skip_one_ch() -> parser.Parser(Token) {
  parser.replace(parser.any_gc(), Unknown)
}

fn token() -> parser.Parser(Token) {
  parser.any([mul(), do(), dont(), skip_one_ch()])
}

fn process_tokens(tokens: List(Token)) {
  tokens
  |> list.fold(#(True, 0), fn(acc, t) {
    case t {
      Do -> #(True, acc.1)
      Dont -> #(False, acc.1)
      Num(n) ->
        case acc.0 {
          True -> #(acc.0, acc.1 + n)
          False -> acc
        }
      Unknown -> panic as "unknowns should have been filtered out by now"
    }
  })
  |> pair.second
}

fn part1(tokens: List(Token)) {
  tokens
  |> list.filter(fn(x) {
    case x {
      Num(_) -> True
      _ -> False
    }
  })
  |> process_tokens
  |> io.debug
}

fn part2(tokens: List(Token)) {
  tokens
  |> list.filter(fn(x) { x != Unknown })
  |> process_tokens
  |> io.debug
}

pub fn main() {
  let assert Ok(f) = utils.read_file("input/y2024/d03/input.txt")
  let assert Ok(tokens) = f |> parser.parse_entire(parser.many0(token()))

  tokens |> part1
  tokens |> part2
}
