import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import parser
import utils

type Field =
  #(String, List(#(Int, Int)))

fn parse_ranges() -> parser.Parser(List(#(Int, Int))) {
  parser.sep1(parse_range(), parser.literal(" or "))
}

fn parse_range() -> parser.Parser(#(Int, Int)) {
  parser.int()
  |> parser.skip(parser.literal("-"))
  |> parser.then(parser.int())
}

fn parse_field() -> parser.Parser(Field) {
  parser.str_of_many1(parser.gc_not_in(":"))
  |> parser.skip(parser.literal(": "))
  |> parser.then(parse_ranges())
}

fn parse_fields() -> parser.Parser(List(Field)) {
  parser.sep1(parse_field(), parser.nl())
}

fn parse_ticket() -> parser.Parser(List(Int)) {
  parser.sep1(parser.int(), parser.literal(","))
}

fn parse_tickets() -> parser.Parser(List(List(Int))) {
  parser.sep1(parse_ticket(), parser.nl())
}

fn in_range(number: Int, range: #(Int, Int)) -> Bool {
  case number >= range.0, number <= range.1 {
    True, True -> True
    _, _ -> False
  }
}

fn part1(fields: List(Field), nearby_tickets: List(List(Int))) {
  nearby_tickets
  |> list.flat_map(fn(numbers_on_ticket) {
    numbers_on_ticket
    |> list.filter(fn(num) {
      let can_be_valid =
        fields
        |> list.flat_map(pair.second)
        |> list.any(fn(range) { in_range(num, range) })
      !can_be_valid
    })
  })
  |> io.debug
  |> list.reduce(int.add)
  |> io.debug
}

pub fn main() {
  let assert Ok(f) = utils.read_file("input/d16/input.txt")

  let assert Ok(#(fields, nearby_tickets)) =
    parser.parse_entire(
      f,
      parse_fields()
        |> parser.skip(parser.literal("\n\nyour ticket:\n"))
        |> parser.skip(parse_ticket())
        |> parser.skip(parser.literal("\n\nnearby tickets:\n"))
        |> parser.then(parse_tickets())
        |> parser.skip_ws,
    )

  part1(fields, nearby_tickets)
}
