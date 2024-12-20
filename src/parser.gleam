// Copied from https://github.com/tchojnacki/advent-of-code/blob/main/aoc-2020-gleam/src/util/parser.gleam

import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/pair
import gleam/result as res
import gleam/string as str

const eof = "EOF"

const unknown = "UNKNOWN"

const whitespace_range = " \t\n"

const alpha_range = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

fn q_s(string: String) -> String {
  "'" <> string <> "'"
}

fn q_d(string: String) -> String {
  "\"" <> string <> "\""
}

pub type ParseError {
  InvalidInput(expected: String, found: String)
  InvalidOperation(ran: String, with: String)
  InvalidParser
}

type ParseResult(a) =
  Result(#(a, String), ParseError)

pub opaque type Parser(a) {
  Parser(function: fn(String) -> ParseResult(a), label: String)
}

fn create(function: fn(String) -> ParseResult(a)) {
  Parser(function, unknown)
}

fn run(parser: Parser(a), on input: String) -> ParseResult(a) {
  parser.function(input)
}

pub fn labeled(parser: Parser(a), with label: String) -> Parser(a) {
  Parser(
    fn(input) {
      run(parser, on: input)
      |> res.map_error(with: fn(error) {
        case error {
          InvalidInput(_, found) -> InvalidInput(label, found)
          other -> other
        }
      })
    },
    label: label,
  )
}

pub fn parse_partial(
  input: String,
  with parser: Parser(a),
) -> Result(#(a, String), ParseError) {
  run(parser, on: input)
}

pub fn parse_entire(
  input: String,
  with parser: Parser(a),
) -> Result(a, ParseError) {
  case parse_partial(input, with: parser) {
    Ok(#(value, "")) -> Ok(value)
    Ok(#(_, rest)) -> Error(InvalidInput(expected: eof, found: q_d(rest)))
    Error(error) -> Error(error)
  }
}

fn gc_satisfying(rule predicate: fn(String) -> Bool) -> Parser(String) {
  create(fn(input) {
    case str.pop_grapheme(input) {
      Ok(#(value, remaining)) ->
        case predicate(value) {
          True -> Ok(#(value, remaining))
          False -> Error(InvalidInput(expected: unknown, found: q_s(value)))
        }
      Error(_) -> Error(InvalidInput(expected: unknown, found: eof))
    }
  })
}

pub fn any_gc() -> Parser(String) {
  gc_satisfying(rule: fn(_) { True })
  |> labeled(with: "any_gc")
}

pub fn gc_in(range allowed: String) -> Parser(String) {
  gc_satisfying(rule: str.contains(allowed, _))
  |> labeled(with: "gc_in(range: " <> q_d(allowed) <> ")")
}

pub fn gc_not_in(range denied: String) -> Parser(String) {
  gc_satisfying(rule: fn(x) { !str.contains(denied, x) })
  |> labeled(with: "gc_not_in(range: " <> q_d(denied) <> ")")
}

pub fn ws_gc() -> Parser(String) {
  gc_in(range: whitespace_range)
  |> labeled(with: "ws_gc")
}

pub fn non_ws_gc() -> Parser(String) {
  gc_not_in(range: whitespace_range)
  |> labeled(with: "non_ws_gc")
}

pub fn alpha_gc() -> Parser(String) {
  gc_in(range: alpha_range)
  |> labeled(with: "alpha_gc")
}

pub fn alpha0() -> Parser(String) {
  str_of_many0(of: alpha_gc())
}

pub fn alpha1() -> Parser(String) {
  str_of_many1(of: alpha_gc())
}

pub fn ws0() -> Parser(String) {
  str_of_many0(of: ws_gc())
}

pub fn ws1() -> Parser(String) {
  str_of_many1(of: ws_gc())
}

pub fn nl() -> Parser(String) {
  gc_in("\n")
  |> labeled(with: "nl")
}

pub fn nlnl() -> Parser(String) {
  literal("\n\n")
  |> labeled(with: "nlnl")
}

pub fn str0_until_ws() -> Parser(String) {
  str_of_many0(of: non_ws_gc())
}

pub fn str1_until_ws() -> Parser(String) {
  str_of_many1(of: non_ws_gc())
}

pub fn skip_ws(after parser: Parser(a)) -> Parser(a) {
  parser
  |> skip(ws0())
}

pub fn replace(parser: Parser(a), with value: b) -> Parser(b) {
  map(parser, with: fn(_) { value })
}

pub fn ignore(parser: Parser(a)) -> Parser(Nil) {
  replace(parser, with: Nil)
}

pub fn then(first: Parser(a), second: Parser(b)) -> Parser(#(a, b)) {
  create(fn(input) {
    use #(value1, remaining1) <- res.then(run(first, on: input))
    use #(value2, remaining2) <- res.then(run(second, on: remaining1))
    Ok(#(#(value1, value2), remaining2))
  })
  |> labeled(with: first.label <> " |> then(" <> second.label <> ")")
}

pub fn skip(first: Parser(a), second: Parser(b)) -> Parser(a) {
  first
  |> then(second)
  |> map(with: pair.first)
}

pub fn proceed(first: Parser(a), with second: Parser(b)) -> Parser(b) {
  first
  |> then(second)
  |> map(with: pair.second)
}

pub fn then_3rd(two: Parser(#(a, b)), third: Parser(c)) -> Parser(#(a, b, c)) {
  two
  |> then(third)
  |> map(with: fn(tuple) {
    let #(#(p0, p1), p2) = tuple
    #(p0, p1, p2)
  })
}

pub fn or(first: Parser(a), otherwise second: Parser(a)) -> Parser(a) {
  create(fn(input) {
    first
    |> run(on: input)
    |> res.or(run(second, on: input))
  })
  |> labeled(with: first.label <> " |> or(otherwise: " <> second.label <> ")")
}

pub fn opt(parser: Parser(a)) -> Parser(Option(a)) {
  parser
  |> map(with: Some)
  |> or(otherwise: succeeding(with: None))
  |> labeled(with: "opt(" <> parser.label <> ")")
}

pub fn any(of parsers: List(Parser(a))) -> Parser(a) {
  parsers
  |> list.reduce(with: or)
  |> res.unwrap(or: failing(with: InvalidParser))
  |> labeled(
    "any(of: ["
    <> {
      parsers
      |> list.map(with: fn(p) { p.label })
      |> str.join(with: ", ")
    }
    <> "])",
  )
}

pub fn digit() -> Parser(String) {
  gc_in(range: "0123456789")
  |> labeled(with: "digit")
}

fn flat_map(
  parser: Parser(a),
  with mapper: fn(a) -> Result(b, ParseError),
) -> Parser(b) {
  create(fn(input) {
    use #(value, remaining) <- res.then(run(parser, on: input))
    value
    |> mapper
    |> res.map(with: fn(new_value) { #(new_value, remaining) })
  })
  |> labeled(with: parser.label)
}

pub fn map(parser: Parser(a), with mapper: fn(a) -> b) -> Parser(b) {
  flat_map(parser, with: fn(value) { Ok(mapper(value)) })
}

pub fn map2(parser: Parser(#(a, b)), with mapper: fn(a, b) -> c) -> Parser(c) {
  map(parser, with: fn(args) { mapper(args.0, args.1) })
}

pub fn map3(
  parser: Parser(#(a, b, c)),
  with mapper: fn(a, b, c) -> d,
) -> Parser(d) {
  map(parser, with: fn(args) { mapper(args.0, args.1, args.2) })
}

fn succeeding(with value: a) -> Parser(a) {
  create(fn(input) { Ok(#(value, input)) })
}

fn failing(with error: ParseError) -> Parser(a) {
  create(fn(_) { Error(error) })
}

fn lift2(function: fn(a, b) -> c) -> fn(Parser(a), Parser(b)) -> Parser(c) {
  fn(x_parser, y_parser) {
    function
    |> succeeding
    |> then(x_parser)
    |> then_3rd(y_parser)
    |> map3(with: fn(f, x, y) { f(x, y) })
  }
}

pub fn seq(of parsers: List(Parser(a))) -> Parser(List(a)) {
  let prepend_parser = lift2(fn(x, xs) { [x, ..xs] })
  case parsers {
    [] -> succeeding(with: [])
    [head, ..tail] ->
      tail
      |> seq
      |> prepend_parser(head, _)
  }
  |> labeled(
    with: "seq(of: ["
    <> {
      parsers
      |> list.map(with: fn(p) { p.label })
      |> str.join(", ")
    }
    <> "])",
  )
}

pub fn str_of_seq(of parsers: List(Parser(String))) -> Parser(String) {
  parsers
  |> seq
  |> map(with: str.concat)
}

fn do_between(
  input: String,
  acc: List(a),
  parser: Parser(a),
  min: Int,
  max: Int,
) -> Result(#(List(a), String), ParseError) {
  case run(parser, on: input) {
    Ok(#(value, rest)) -> {
      case max > 0 {
        // Max doesn't allow looking for more
        False -> Ok(#([value, ..acc], rest))
        // Max allows looking for more
        True -> do_between(rest, [value, ..acc], parser, min - 1, max - 1)
      }
    }
    Error(err) ->
      case min <= 0 {
        // Min is zero, found valid match
        True -> Ok(#(list.reverse(acc), input))
        // Min is non-zero, needed more -> invalid
        False -> Error(err)
      }
  }
}

pub fn between(parser: Parser(a), min: Int, max: Int) -> Parser(List(a)) {
  create(fn(input) { do_between(input, [], parser, min, max) })
  |> labeled(
    with: "between(min: "
    <> int.to_string(min)
    <> ", max: "
    <> int.to_string(max)
    <> ", of: "
    <> parser.label
    <> ")",
  )
}

fn do_zero_or_more(input: String, with parser: Parser(a)) -> #(List(a), String) {
  case run(parser, on: input) {
    Ok(#(value, rest)) -> {
      let #(previous, rest) = do_zero_or_more(rest, with: parser)
      #([value, ..previous], rest)
    }
    Error(_) -> #([], input)
  }
}

pub fn many0(of parser: Parser(a)) -> Parser(List(a)) {
  create(fn(input) { Ok(do_zero_or_more(input, with: parser)) })
  |> labeled(with: "many(of: " <> parser.label <> ")")
}

pub fn str_of_many0(of parser: Parser(String)) -> Parser(String) {
  parser
  |> many0
  |> map(with: str.concat)
}

pub fn many1(of parser: Parser(a)) -> Parser(List(a)) {
  create(fn(input) {
    use #(value, rest) <- res.then(run(parser, on: input))
    let #(previous, rest) = do_zero_or_more(rest, with: parser)
    Ok(#([value, ..previous], rest))
  })
  |> labeled(with: "many1(of: " <> parser.label <> ")")
}

pub fn str_of_many1(of parser: Parser(String)) -> Parser(String) {
  parser
  |> many1
  |> map(with: str.concat)
}

pub fn sep1(parser: Parser(a), by separator: Parser(b)) -> Parser(List(a)) {
  parser
  |> then(many0(of: proceed(separator, parser)))
  |> map2(with: fn(p, ps) { [p, ..ps] })
  |> labeled(
    with: "sep1(" <> parser.label <> ", by: " <> separator.label <> ")",
  )
}

pub fn sep0(parser: Parser(a), by separator: Parser(b)) -> Parser(List(a)) {
  parser
  |> sep1(by: separator)
  |> or(otherwise: succeeding(with: []))
  |> labeled(
    with: "sep0(" <> parser.label <> ", by: " <> separator.label <> ")",
  )
}

pub fn int() -> Parser(Int) {
  opt(literal("-"))
  |> then(digit() |> str_of_many1)
  |> flat_map(with: fn(in) {
    let #(sign, digits) = in
    digits
    |> int.parse
    |> res.try(fn(n) {
      Ok(case sign {
        Some(_) -> n * -1
        None -> n
      })
    })
    |> res.replace_error(InvalidOperation(ran: "int.parse", with: digits))
  })
  |> labeled(with: "int")
}

pub fn any_str_greedy() -> Parser(String) {
  any_gc()
  |> str_of_many0
  |> labeled(with: "any_str_greedy")
}

pub fn literal(expected: String) -> Parser(String) {
  expected
  |> str.to_graphemes
  |> list.map(with: fn(eg) { gc_satisfying(fn(g) { g == eg }) })
  |> str_of_seq
  |> labeled(with: q_d(expected))
}

pub fn str_of_len(parser: Parser(String), length: Int) -> Parser(String) {
  parser
  |> list.repeat(times: length)
  |> str_of_seq
  |> labeled(
    with: "str_of_len(" <> parser.label <> "," <> int.to_string(length) <> ")",
  )
}

pub fn any_str_of_len(length: Int) -> Parser(String) {
  str_of_len(any_gc(), length)
}

pub fn repeat(parser: Parser(a), times times: Int) -> Parser(List(a)) {
  parser
  |> list.repeat(times: times)
  |> seq
  |> labeled(
    with: parser.label <> " |> repeat(times: " <> int.to_string(times) <> ")",
  )
}

pub fn satisfying(parser: Parser(a), rule predicate: fn(a) -> Bool) -> Parser(a) {
  create(fn(input) {
    use parsed <- res.then(run(parser, on: input))
    let #(value, _) = parsed
    case predicate(value) {
      True -> Ok(parsed)
      False ->
        Error(InvalidOperation(
          ran: str.inspect(predicate),
          with: str.inspect(value),
        ))
    }
  })
  |> labeled(with: parser.label)
}
