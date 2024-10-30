import gleam/bool
import gleam/dict
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

fn matches_field(number: Int, field: Field) -> Bool {
  field.1
  |> list.any(fn(range) { in_range(number, range) })
}

fn find_fields_matching_all_numbers(
  numbers: List(Int),
  fields: List(Field),
) -> List(Field) {
  fields
  |> list.filter(fn(field) {
    numbers
    |> list.all(matches_field(_, field))
  })
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
  |> list.reduce(int.add)
  |> io.debug
}

fn solve(
  state: List(#(Int, List(String))),
  solved: List(#(Int, String)),
) -> List(#(Int, String)) {
  use <- bool.guard(when: list.is_empty(state), return: solved)

  // Find the ones where there's only one remaining option
  let #(now_solved, remaining) =
    state
    |> list.partition(fn(s) {
      let #(_, fields) = s
      case fields {
        [_] -> True
        _ -> False
      }
    })

  // Turn List([field]) into field
  let now_solved =
    now_solved
    |> list.map(fn(s) {
      let #(num, fields) = s
      let assert Ok(field) = list.first(fields)
      #(num, field)
    })

  // Remove now solved from the options remaining
  let remaining =
    remaining
    |> list.map(fn(rem) {
      let #(num, fields) = rem
      #(
        num,
        fields
          |> list.filter(fn(f) { now_solved |> list.all(fn(ns) { ns.1 != f }) }),
      )
    })

  let solved = list.append(solved, now_solved)

  solve(remaining, solved)
}

fn part2(
  fields: List(Field),
  my_ticket: List(Int),
  nearby_tickets: List(List(Int)),
) {
  let valid_tickets =
    nearby_tickets
    |> list.filter(fn(numbers_on_ticket) {
      numbers_on_ticket
      |> list.all(fn(num) {
        let can_be_valid =
          fields
          |> list.flat_map(pair.second)
          |> list.any(fn(range) { in_range(num, range) })
        can_be_valid
      })
    })

  let state =
    valid_tickets
    |> list.transpose
    |> list.index_map(fn(numbers_for_field, i) {
      #(
        i,
        find_fields_matching_all_numbers(numbers_for_field, fields)
          |> list.map(pair.first),
      )
    })

  let solution = solve(state, [])

  let my_ticket = utils.list_to_indexed_dict(my_ticket)

  solution
  |> list.filter_map(fn(sol) {
    let #(num, name) = sol
    case name {
      "departure " <> _ -> Ok(num)
      _ -> Error(Nil)
    }
  })
  |> list.map(fn(n) {
    let assert Ok(res) = dict.get(my_ticket, n)
    res
  })
  |> list.reduce(int.multiply)
  |> io.debug
}

pub fn main() {
  let assert Ok(f) = utils.read_file("input/d16/input.txt")

  let assert Ok(#(fields, my_ticket, nearby_tickets)) =
    parser.parse_entire(
      f,
      parse_fields()
        |> parser.skip(parser.literal("\n\nyour ticket:\n"))
        |> parser.then(parse_ticket())
        |> parser.skip(parser.literal("\n\nnearby tickets:\n"))
        |> parser.then_3rd(parse_tickets())
        |> parser.skip_ws,
    )

  let _ = part1(fields, nearby_tickets)
  part2(fields, my_ticket, nearby_tickets)
}
