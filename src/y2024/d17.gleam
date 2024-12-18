import gleam/bool
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

fn instruction_to_string(i: Int) -> String {
  case i {
    0 -> "adv"
    1 -> "bxl"
    2 -> "bst"
    3 -> "jnz"
    4 -> "bxc"
    5 -> "out"
    6 -> "bdv"
    7 -> "cdv"
    _ -> panic as "unexpected instruction"
  }
}

fn last_octet(x: Int) {
  x % 8 |> int.to_base2 |> string.pad_start(3, "0")
}

pub fn output_state(c: Computer, instr: Int) -> Nil {
  io.println("A: " <> c.a |> int.to_base2 |> string.pad_start(3, "0"))
  io.println("B: " <> c.b |> last_octet <> " (" <> int.to_string(c.b) <> ")")
  io.println("C: " <> c.c |> last_octet)

  list.range(0, list.length(c.program) - 1)
  |> list.map(fn(i) {
    int.to_string(i)
    |> string.pad_start(3, " ")
  })
  |> string.join(" ")

  c.program
  |> list.map(fn(x) { "(" <> x |> int.to_string <> ")" })
  |> string.join(" ")

  c.program
  |> list.index_map(fn(i, idx) {
    case idx % 2 {
      0 -> instruction_to_string(i)
      _ -> " _ "
    }
  })
  |> string.join(" ")

  string.pad_start("^", c.ip * 4 + 2, " ")

  c.out
  |> list.reverse
  |> list.map(int.to_string)
  |> string.join(" ")
  |> string.append("out: ", _)
  |> io.println

  io.println(" ")
  io.println(instruction_to_string(instr) |> string.uppercase)
  io.println(" ")
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
      //output_state(c, instruction, operand)
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

pub fn part1(computer: Computer) {
  execute(computer)
  |> list.map(int.to_string)
  |> string.join(",")
  |> io.println
}

fn valid_next_octets(c: Computer, existing_a: Int, len: Int) -> List(Int) {
  let target = c.program |> list.reverse |> list.take(len + 1) |> list.reverse
  list.range(0, 7)
  |> list.filter_map(fn(x) {
    let x = existing_a * 8 + x
    let res = execute(Computer(..c, a: x))
    case res == target {
      True -> Ok(x)
      False -> Error(Nil)
    }
  })
}

pub fn find_part2(c: Computer, existing_a: Int, len: Int) -> List(Int) {
  case len == list.length(c.program) - 1 {
    True -> valid_next_octets(c, existing_a, len)
    False -> {
      let nexts = valid_next_octets(c, existing_a, len)

      nexts
      |> list.flat_map(find_part2(c, _, len + 1))
    }
  }
}

pub fn part2(computer: Computer) {
  find_part2(computer, 0, 0) |> list.sort(int.compare) |> list.first |> io.debug
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

  let _ = part1(computer)
  let _ = part2(computer)
}
