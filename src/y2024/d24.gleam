import gleam/bool
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/string
import utils

pub type Op {
  And
  Or
  Xor
}

pub type Gate {
  Gate(in1: String, in2: String, out: String, op: Op)
}

pub type Circuit {
  Circuit(wires: dict.Dict(String, Bool), gates: List(Gate))
}

fn simulate_until_stable(c: Circuit) -> Circuit {
  let next = simulate(c)
  case next.wires == c.wires {
    True -> next
    False -> simulate_until_stable(next)
  }
}

fn simulate(c: Circuit) -> Circuit {
  let wires =
    c.gates
    |> list.fold(c.wires, fn(wires, gate) {
      let in_val_1 = dict.get(c.wires, gate.in1)
      let in_val_2 = dict.get(c.wires, gate.in2)
      let out_val = dict.get(c.wires, gate.out)

      case in_val_1, in_val_2, out_val {
        Ok(in_val_1), Ok(in_val_2), Error(_) -> {
          let out_val = case gate.op {
            And -> in_val_1 && in_val_2
            Or -> in_val_1 || in_val_2
            Xor -> bool.exclusive_or(in_val_1, in_val_2)
          }
          wires |> dict.insert(gate.out, out_val)
        }
        _, _, _ -> wires
      }
    })

  Circuit(wires, c.gates)
}

fn z_value(c: Circuit) -> Int {
  c.wires
  |> dict.filter(fn(k, _v) { string.starts_with(k, "z") })
  |> dict.to_list
  |> list.sort(fn(a, b) { string.compare(a.0, b.0) })
  |> list.reverse
  |> list.map(pair.second)
  |> list.fold(0, fn(acc, x) {
    let val = case x {
      True -> 1
      False -> 0
    }
    acc * 2 + val
  })
}

pub fn main() {
  let assert Ok([wire_values, gates]) =
    utils.read_file_split_by("input/y2024/d24/input.txt", "\n\n")

  let wires =
    wire_values
    |> string.split("\n")
    |> list.map(fn(line) {
      let assert Ok(#(wire, value)) = line |> string.split_once(": ")
      let assert Ok(value) = value |> int.parse
      #(wire, value == 1)
    })
    |> dict.from_list

  let gates =
    gates
    |> string.split("\n")
    |> list.map(fn(line) {
      let assert Ok(#(left, right)) = line |> string.split_once(" -> ")
      let assert [in1, op, in2] = left |> string.split(" ")
      let op = case op {
        "AND" -> And
        "OR" -> Or
        "XOR" -> Xor
        _ -> panic as "unexpected operation"
      }
      Gate(in1, in2, right, op)
    })

  let c = Circuit(wires, gates)
  simulate_until_stable(c)
  |> z_value
  |> io.debug
}
