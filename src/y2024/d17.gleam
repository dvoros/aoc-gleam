import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import utils

pub type Computer {
  Computer(a: Int, b: Int, c: Int, program: List(Int), ip: Int, out: List(Int))
}

fn combo(c: Computer, operand: Int) -> Int {
  case operand {
    0 | 1 | 2 | 3 -> operand
    4 -> c.a
    5 -> c.b
    6 -> c.c
    _ -> panic as "invalid combo operand"
  }
}

fn div(c: Computer, operand: Int) {
  c.a / utils.intpow(2, combo(c, operand))
}

fn execute(c: Computer) -> List(Int) {
  do_execute(c).out |> list.reverse
}

fn do_execute(c: Computer) -> Computer {
  let next =
    c.program
    |> list.drop(c.ip)
    |> list.take(2)

  case next {
    [instruction, operand] -> {
      let c = Computer(..c, ip: c.ip + 2)
      let c = case instruction {
        0 -> Computer(..c, a: div(c, operand))
        1 -> Computer(..c, b: int.bitwise_exclusive_or(c.b, operand))
        2 -> Computer(..c, b: combo(c, operand) % 8)
        3 ->
          Computer(
            ..c,
            ip: case c.a != 0 {
              True -> operand
              False -> c.ip
            },
          )
        4 -> Computer(..c, b: int.bitwise_exclusive_or(c.b, c.c))
        5 -> Computer(..c, out: [combo(c, operand) % 8, ..c.out])
        6 -> Computer(..c, b: div(c, operand))
        7 -> Computer(..c, c: div(c, operand))

        _ -> panic as "unexpected instruction"
      }
      do_execute(c)
    }
    _ -> c
  }
}

pub fn main() {
  let assert Ok([first, _, _, _, last]) =
    utils.read_lines_from_file("input/y2024/d17/input.txt")

  let assert Ok(a) =
    first
    |> string.split_once(": ")
    |> result.unwrap(#("", ""))
    |> pair.second
    |> int.parse

  let program =
    last
    |> string.split_once(" ")
    |> result.unwrap(#("", ""))
    |> pair.second
    |> string.split(",")
    |> list.filter_map(int.parse)

  let computer = Computer(a, 0, 0, program, 0, [])

  execute(computer)
  |> list.map(int.to_string)
  |> string.join(",")
  |> io.println
}
