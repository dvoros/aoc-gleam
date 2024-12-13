import gleam/int
import gleam/io
import gleam/list
import parser
import utils

pub type Machine {
  Machine(a: #(Int, Int), b: #(Int, Int), target: #(Int, Int))
}

fn parse_button() -> parser.Parser(#(Int, Int)) {
  parser.literal("Button ")
  |> parser.proceed(parser.any_gc())
  |> parser.proceed(parser.literal(": X+"))
  |> parser.proceed(parser.int())
  |> parser.skip(parser.literal(", Y+"))
  |> parser.then(parser.int())
  |> parser.skip(parser.ws0())
}

fn parse_prize() -> parser.Parser(#(Int, Int)) {
  parser.literal("Prize: X=")
  |> parser.proceed(parser.int())
  |> parser.skip(parser.literal(", Y="))
  |> parser.then(parser.int())
  |> parser.skip(parser.ws0())
}

fn parse_machine(machine: String) -> Result(Machine, Nil) {
  let assert Ok(#(a, b, prize)) =
    parser.parse_entire(
      machine,
      parse_button()
        |> parser.then(parse_button())
        |> parser.then_3rd(parse_prize()),
    )
  Ok(Machine(a, b, prize))
}

fn is_winning(machine: Machine, combination: #(Int, Int)) -> Bool {
  machine.a.0 * combination.0 + machine.b.0 * combination.1 == machine.target.0
  && machine.a.1 * combination.0 + machine.b.1 * combination.1
  == machine.target.1
}

fn solve(m: Machine) -> Result(Int, Nil) {
  let b =
    { m.a.0 * m.target.1 - m.a.1 * m.target.0 }
    / { m.a.0 * m.b.1 - m.a.1 * m.b.0 }
  let a = { m.target.0 - m.b.0 * b } / m.a.0
  case is_winning(m, #(a, b)) {
    True -> Ok(3 * a + b)
    False -> Error(Nil)
  }
}

fn part1(machines: List(Machine)) {
  machines
  |> list.filter_map(solve)
  |> list.reduce(int.add)
  |> io.debug
}

fn part2(machines: List(Machine)) {
  machines
  |> list.map(fn(m) {
    Machine(
      ..m,
      target: #(
        m.target.0 + 10_000_000_000_000,
        m.target.1 + 10_000_000_000_000,
      ),
    )
  })
  |> part1
}

pub fn main() {
  let assert Ok(machines) =
    utils.parse_empty_line_separated_blocks_from_file(
      "input/y2024/d13/input.txt",
      parse_machine,
    )
  let _ = part1(machines)
  let _ = part2(machines)
}
