import gleam/dict
import gleam/int
import gleam/io
import gleam/result
import gleam/set
import utils

pub type Machine {
  Machine(instructions: dict.Dict(Int, Instruction), position: Int, acc: Int)
}

pub type Instruction {
  Acc(Int)
  Jmp(Int)
  Nop(Int)
}

pub fn parse_number(str: String) -> Int {
  case str {
    "+" <> n -> int.parse(n) |> result.unwrap(0)
    "-" <> n -> -1 * { int.parse(n) |> result.unwrap(0) }
    _ -> 0
  }
}

pub fn parse_instruction(str: String) -> Result(Instruction, Nil) {
  case str {
    "acc " <> n -> Ok(Acc(parse_number(n)))
    "jmp " <> n -> Ok(Jmp(parse_number(n)))
    "nop " <> n -> Ok(Nop(parse_number(n)))
    _ -> Error(Nil)
  }
}

pub fn new_machine(instructions: dict.Dict(Int, Instruction)) -> Machine {
  Machine(instructions, 0, 0)
}

pub fn get_instruction_at(m: Machine, p: Int) -> Result(Instruction, Nil) {
  m.instructions
  |> dict.get(p)
}

pub fn current_instruction(m: Machine) -> Result(Instruction, Nil) {
  get_instruction_at(m, m.position)
}

pub fn step(machine: Machine) -> Machine {
  let instruction = current_instruction(machine) |> result.unwrap(Nop(0))
  let #(position, acc) = case instruction {
    Acc(n) -> #(machine.position + 1, machine.acc + n)
    Jmp(n) -> #(machine.position + n, machine.acc)
    _ -> #(machine.position + 1, machine.acc)
  }
  Machine(..machine, position: position, acc: acc)
}

pub fn find_acc_at_loop(machine: Machine) -> #(Bool, Int) {
  find_acc_at_loop_rec(machine, set.new())
}

fn find_acc_at_loop_rec(
  machine: Machine,
  visited_positions: set.Set(Int),
) -> #(Bool, Int) {
  //   #(machine, visited_positions) |> io.debug
  case machine.position == dict.size(machine.instructions) {
    True -> #(False, machine.acc)
    False ->
      case set.contains(visited_positions, machine.position) {
        True -> #(True, machine.acc)
        False ->
          find_acc_at_loop_rec(
            step(machine),
            set.insert(visited_positions, machine.position),
          )
      }
  }
}

pub fn part1(machine: Machine) {
  find_acc_at_loop(machine) |> io.debug
}

pub fn flip_nop_jmp(machine: Machine, pos: Int) -> Machine {
  let new_instructions =
    dict.insert(machine.instructions, pos, case
      get_instruction_at(machine, pos) |> result.unwrap(Acc(0))
    {
      Acc(n) -> Acc(n)
      Jmp(n) -> Nop(n)
      Nop(n) -> Jmp(n)
    })
  Machine(..machine, instructions: new_instructions)
}

pub fn part2(machine: Machine) {
  machine.instructions
  |> dict.filter(fn(_, inst) {
    case inst {
      Acc(_) -> False
      _ -> True
    }
  })
  |> dict.map_values(fn(pos, _) {
    machine |> flip_nop_jmp(pos) |> find_acc_at_loop()
  })
  |> dict.filter(fn(_, r) {
    let #(loop, _) = r
    !loop
  })
  |> io.debug
}

pub fn main() {
  let machine =
    utils.parse_lines_from_file("input/y2020/d08/input.txt", parse_instruction)
    |> result.unwrap([])
    |> utils.list_to_dict_by_index()
    |> new_machine()
  part1(machine)
  part2(machine)
}
