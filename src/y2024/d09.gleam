import gleam/bool
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/string
import utils

pub type State {
  State(
    value_map: dict.Dict(Int, Int),
    value_list: List(Int),
    empties: List(Int),
    pos: Int,
  )
}

fn new_state() {
  State(dict.new(), [], [], 0)
}

fn move_all(s: State) -> State {
  case list.is_empty(s.empties) {
    True -> s
    False -> move_all(move(s))
  }
}

fn move(s: State) -> State {
  use <- bool.guard(list.is_empty(s.empties), s)

  let assert [empty_pos, ..rest_empties] = s.empties
  let assert [value, ..rest_value_list] = s.value_list

  State(
    dict.insert(s.value_map, empty_pos, value),
    rest_value_list,
    rest_empties,
    s.pos - 1,
  )
}

fn checksum(s: State) -> Int {
  list.range(0, s.pos - 1)
  |> list.fold(0, fn(acc, i) {
    let assert Ok(x) = dict.get(s.value_map, i)
    acc + i * x
  })
}

pub fn part1(line: String) {
  line
  |> string.to_graphemes
  |> list.index_fold(new_state(), fn(state, v, idx) {
    let assert Ok(v) = int.parse(v)
    use <- bool.guard(when: v == 0, return: state)

    let indexes = list.range(state.pos, state.pos + v - 1)
    case idx |> int.is_even {
      True -> {
        let id = idx / 2
        let value_map =
          list.fold(indexes, state.value_map, fn(acc, i) {
            dict.insert(acc, i, id)
          })
        let value_list =
          list.fold(indexes, state.value_list, fn(acc, _) { [id, ..acc] })
        State(
          ..state,
          value_map: value_map,
          value_list: value_list,
          pos: state.pos + v,
        )
      }
      False -> {
        let empties = list.append(state.empties, indexes)
        State(..state, empties: empties, pos: state.pos + v)
      }
    }
  })
  |> move_all
  |> checksum
  |> io.debug
}

pub type Block {
  File(idx: Int, size: Int, v: Int)
  Empty(idx: Int, size: Int)
}

pub fn move2(empties: List(Block), file: Block) {
  let assert File(file_idx, file_size, file_v) = file
  empties
  |> list.map_fold(Empty(0, 0), fn(found, e) {
    case found {
      Empty(_, _) -> {
        let assert Empty(empty_idx, empty_size) = e
        case empty_size >= file_size && file_idx > empty_idx {
          True -> #(
            File(empty_idx, file_size, file_v),
            Empty(empty_idx + file_size, empty_size - file_size),
          )
          False -> #(Empty(0, 0), e)
        }
      }
      f -> #(f, e)
    }
  })
}

pub fn checksum2(files: List(Block)) {
  files
  |> list.filter_map(fn(f) {
    let assert File(f_idx, f_size, f_v) = f
    list.range(f_idx, f_idx + f_size - 1)
    |> list.map(fn(x) { x * f_v })
    |> list.reduce(int.add)
  })
  |> list.reduce(int.add)
}

pub fn part2(line: String) {
  let blocks =
    line
    |> string.to_graphemes
    |> list.index_fold(#(0, []), fn(acc, x, idx) {
      let assert Ok(x) = int.parse(x)
      let id = idx / 2
      case idx |> int.is_even {
        True -> #(acc.0 + x, [File(acc.0, x, id), ..acc.1])
        False -> #(acc.0 + x, [Empty(acc.0, x), ..acc.1])
      }
    })

  let blocks = blocks.1 |> list.reverse

  let #(files, empties) =
    blocks
    |> list.partition(fn(x) {
      case x {
        File(_, _, _) -> True
        _ -> False
      }
    })

  let #(_, files_moved) =
    files
    |> list.reverse
    |> list.fold(#(empties, []), fn(acc, file) {
      let #(empties, files_moved) = acc
      let #(changed, new_empties) = move2(empties, file)
      case changed {
        Empty(_, _) -> #(new_empties, files_moved)
        f -> #(new_empties, [f, ..files_moved])
      }
    })

  files
  |> list.map(fn(f) {
    let assert File(_, _, f_v) = f
    case
      list.find(files_moved, fn(x) {
        let assert File(_, _, x_v) = x
        x_v == f_v
      })
    {
      Ok(found) -> found
      Error(_) -> f
    }
  })
  |> checksum2
  |> io.debug
}

pub fn main() {
  let assert Ok(line) = utils.read_file("input/y2024/d09/input.txt")
  let line = line |> string.trim

  part1(line)
  part2(line)
}
