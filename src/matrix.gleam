import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import utils

pub const coords_4neighbors = [#(-1, 0), #(0, -1), #(0, 1), #(1, 0)]

pub const coords_8neighbors = [
  #(-1, -1), #(-1, 0), #(-1, 1), #(0, -1), #(0, 1), #(1, -1), #(1, 0), #(1, 1),
]

pub type Matrix(a) {
  Matrix(content: dict.Dict(Int, dict.Dict(Int, a)))
}

pub type Cell(a) {
  Cell(row: Int, column: Int, value: a)
}

pub fn cell_value(c: Cell(a)) -> a {
  c.value
}

pub fn new_from_dict_dict(
  content: dict.Dict(Int, dict.Dict(Int, a)),
) -> Matrix(a) {
  Matrix(content)
}

pub fn new_from_list_list(l: List(List(a))) -> Matrix(a) {
  l
  |> list.map(utils.list_to_dict_by_index)
  |> utils.list_to_dict_by_index
  |> new_from_dict_dict
}

pub fn new_from_string_list(l: List(String)) -> Matrix(String) {
  l
  |> list.map(utils.string_to_dict)
  |> utils.list_to_dict_by_index
  |> new_from_dict_dict
}

pub fn get(mx: Matrix(a), r: Int, c: Int) -> Result(a, Nil) {
  use row <- result.try(dict.get(mx.content, r))
  dict.get(row, c)
}

pub fn filter(
  mx: Matrix(a),
  where predicate: fn(a, Int, Int) -> Bool,
) -> List(Cell(a)) {
  mx.content
  |> dict.to_list
  |> list.flat_map(fn(r) {
    let #(r, row) = r
    row
    |> dict.to_list
    |> list.filter_map(fn(c) {
      let #(c, val) = c
      case predicate(val, r, c) {
        True -> Ok(Cell(r, c, val))
        False -> Error(Nil)
      }
    })
  })
}

// Count cells for which a predicate is True.
pub fn count(mx: Matrix(a), where predicate: fn(a, Int, Int) -> Bool) -> Int {
  let res =
    mx.content
    |> dict.map_values(fn(r, row) {
      row
      |> dict.map_values(fn(c, val) { predicate(val, r, c) })
      |> dict.to_list
      |> list.count(fn(x) { x.1 })
    })
    |> dict.to_list
    |> list.map(fn(x) { x.1 })
    |> list.reduce(int.add)
  case res {
    Ok(r) -> r
    _ -> 0
  }
}

pub fn cells_taking_steps(
  mx: Matrix(a),
  from: #(Int, Int),
  taking step: #(Int, Int),
) -> List(Cell(a)) {
  cells_taking_steps_acc(mx, #(from.0 + step.0, from.1 + step.1), step, [])
}

fn cells_taking_steps_acc(
  mx: Matrix(a),
  from: #(Int, Int),
  step: #(Int, Int),
  acc: List(Cell(a)),
) -> List(Cell(a)) {
  let curr = get(mx, from.0, from.1)
  case curr {
    Error(_) -> acc
    Ok(x) ->
      cells_taking_steps_acc(
        mx,
        #(from.0 + step.0, from.1 + step.1),
        step,
        list.append(acc, [Cell(from.0, from.1, x)]),
      )
  }
}

pub fn find_target4(
  mx: Matrix(a),
  from: #(Int, Int),
  target: fn(Cell(a)) -> Bool,
  step_allowed: fn(Cell(a), Cell(a)) -> Bool,
) {
  do_find_target4(mx, from, target, step_allowed, [])
}

fn do_find_target4(
  mx: Matrix(a),
  from: #(Int, Int),
  target: fn(Cell(a)) -> Bool,
  step_allowed: fn(Cell(a), Cell(a)) -> Bool,
  path: List(Cell(a)),
) -> List(List(Cell(a))) {
  let assert Ok(v) = get(mx, from.0, from.1)
  let from_cell = Cell(from.0, from.1, v)
  case target(from_cell) {
    True -> [[from_cell, ..path]]
    False -> {
      allowed_steps4(mx, from, step_allowed)
      |> list.flat_map(fn(next_cell) {
        let next_path = [from_cell, ..path]
        let next_coords = #(next_cell.row, next_cell.column)
        do_find_target4(mx, next_coords, target, step_allowed, next_path)
      })
    }
  }
}

pub fn allowed_steps4(
  mx: Matrix(a),
  from: #(Int, Int),
  step_allowed: fn(Cell(a), Cell(a)) -> Bool,
) {
  let assert Ok(from_val) = get(mx, from.0, from.1)
  let from_cell = Cell(from.0, from.1, from_val)
  neighbors4_cells(mx, from)
  |> list.filter(step_allowed(from_cell, _))
}

pub fn neighbors4_cells(mx: Matrix(a), from: #(Int, Int)) -> List(Cell(a)) {
  coords_4neighbors
  |> list.filter_map(fn(d) {
    let t = #(from.0 + d.0, from.1 + d.1)
    case get(mx, t.0, t.1) {
      Ok(v) -> Ok(Cell(t.0, t.1, v))
      Error(v) -> Error(v)
    }
  })
}

// Returns the neighboring 8 values. If on edge or in corner, it'll
// return fewer.
pub fn neighbors8(mx: Matrix(a), r: Int, c: Int) -> List(a) {
  coords_8neighbors
  |> list.filter_map(fn(p) { get(mx, r + p.0, c + p.1) })
}

// Create new Matrix by applying a function on all cells.
pub fn map(mx: Matrix(a), with fun: fn(a, Int, Int) -> b) -> Matrix(b) {
  mx.content
  |> dict.map_values(fn(r, row) {
    row
    |> dict.map_values(fn(c, val) { fun(val, r, c) })
  })
  |> new_from_dict_dict
}

// Gets size #{rows, cols}
pub fn get_size(mx: Matrix(a)) -> #(Int, Int) {
  #(
    dict.size(mx.content),
    dict.get(mx.content, 0) |> result.unwrap(dict.new()) |> dict.size,
  )
}

fn as_list(row_or_col: dict.Dict(Int, a)) -> List(a) {
  list.range(0, dict.size(row_or_col) - 1)
  |> list.filter_map(dict.get(row_or_col, _))
}

pub fn get_row(mx: Matrix(a), r: Int) -> Result(List(a), Nil) {
  case dict.get(mx.content, r) {
    Error(e) -> Error(e)
    Ok(row) -> Ok(as_list(row))
  }
}

pub fn rows(mx: Matrix(a)) -> List(List(a)) {
  list.range(0, get_size(mx).0 - 1)
  |> list.filter_map(get_row(mx, _))
}

pub fn cols(mx: Matrix(a)) -> List(List(a)) {
  let size = get_size(mx)
  list.range(0, size.1 - 1)
  |> list.map(fn(col) {
    list.range(0, size.0 - 1)
    |> list.filter_map(get(mx, _, col))
  })
}

// All major "\" diagonals
pub fn diagonals_major(mx: Matrix(a)) -> List(List(a)) {
  list.append(
    list.range(get_size(mx).1 - 1, 1)
      |> list.map(fn(c) { #(-1, c - 1) }),
    list.range(0, get_size(mx).0 - 1)
      |> list.map(fn(r) { #(r - 1, -1) }),
  )
  |> list.map(fn(x) {
    cells_taking_steps(mx, x, #(1, 1))
    |> list.map(cell_value)
  })
}

// All minor "/" diagonals
pub fn diagonals_minor(mx: Matrix(a)) -> List(List(a)) {
  list.append(
    list.range(0, get_size(mx).0 - 1)
      |> list.map(fn(r) { #(r + 1, -1) }),
    list.range(1, get_size(mx).1 - 1)
      |> list.map(fn(c) { #(get_size(mx).0, c - 1) }),
  )
  |> list.map(fn(x) {
    cells_taking_steps(mx, x, #(-1, 1))
    |> list.map(cell_value)
  })
}

pub fn debug(mx: Matrix(a)) -> Matrix(a) {
  list.range(0, dict.size(mx.content) - 1)
  |> list.each(fn(x) {
    let assert Ok(row) = mx.content |> dict.get(x)
    list.range(0, dict.size(row) - 1)
    |> list.each(fn(y) {
      let assert Ok(elem) = row |> dict.get(y)
      io.print(elem |> string.inspect)
      io.print(" ")
    })

    io.println("")
  })
  io.println("")

  mx
}
