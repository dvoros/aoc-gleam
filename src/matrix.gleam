import gleam/bool
import gleam/dict
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/set
import gleam/string
import utils

pub const coords_4neighbors = [#(-1, 0), #(0, -1), #(0, 1), #(1, 0)]

pub const coords_8neighbors = [
  #(-1, -1), #(-1, 0), #(-1, 1), #(0, -1), #(0, 1), #(1, -1), #(1, 0), #(1, 1),
]

pub type Matrix(a) {
  Matrix(size: #(Int, Int), content: dict.Dict(#(Int, Int), a))
}

pub type Cell(a) {
  Cell(row: Int, column: Int, value: a)
}

pub type Coord =
  #(Int, Int)

pub fn cell_value(c: Cell(a)) -> a {
  c.value
}

pub fn cell_coord(c: Cell(_)) -> Coord {
  #(c.row, c.column)
}

pub fn add_coord(c1: Coord, c2: Coord) -> Coord {
  #(c1.0 + c2.0, c1.1 + c2.1)
}

pub fn subtract_coord(c1: Coord, c2: Coord) -> Coord {
  #(c1.0 - c2.0, c1.1 - c2.1)
}

pub fn rotate_coord_right(c: Coord) -> Coord {
  #(c.1, -c.0)
}

pub fn new_from_dict_dict(
  content: dict.Dict(Int, dict.Dict(Int, a)),
) -> Matrix(a) {
  let rows = content |> dict.size
  let cols =
    content
    |> dict.to_list
    |> list.first
    |> result.unwrap(#(0, dict.new()))
    |> pair.second
    |> dict.size

  let content =
    content
    |> dict.fold(dict.new(), fn(acc, r, row) {
      row
      |> dict.fold(acc, fn(acc, c, val) { acc |> dict.insert(#(r, c), val) })
    })

  Matrix(#(rows, cols), content)
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

pub fn get_by_coord(mx: Matrix(a), c: Coord) -> Result(a, Nil) {
  get(mx, c.0, c.1)
}

pub fn get(mx: Matrix(a), r: Int, c: Int) -> Result(a, Nil) {
  dict.get(mx.content, #(r, c))
}

pub fn set_by_coord(mx: Matrix(a), c: Coord, value: a) -> Matrix(a) {
  set(mx, c.0, c.1, value)
}

pub fn set(mx: Matrix(a), row: Int, col: Int, value: a) -> Matrix(a) {
  mx
  |> map(fn(v, r, c) {
    case r == row && c == col {
      True -> value
      False -> v
    }
  })
}

pub fn filter(
  mx: Matrix(a),
  where predicate: fn(a, Int, Int) -> Bool,
) -> List(Cell(a)) {
  mx.content
  |> dict.to_list
  |> list.filter_map(fn(x) {
    let #(#(r, c), val) = x
    case predicate(val, r, c) {
      True -> Ok(Cell(r, c, val))
      False -> Error(Nil)
    }
  })
}

// Count cells for which a predicate is True.
pub fn count(mx: Matrix(a), where predicate: fn(a, Int, Int) -> Bool) -> Int {
  filter(mx, predicate) |> list.length
}

fn stop_when_out_of_bounds(mx: Matrix(a), coord: #(Int, Int)) -> Bool {
  case get(mx, coord.0, coord.1) {
    Ok(_) -> False
    Error(_) -> True
  }
}

pub fn path_until(
  mx: Matrix(a),
  from: #(Int, Int),
  step: #(Int, Int),
  until stop: fn(Matrix(a), #(Int, Int)) -> Bool,
) {
  cells_taking_steps_acc(
    mx,
    #(from.0 + step.0, from.1 + step.1),
    step,
    [],
    stop,
  )
}

pub fn cells_taking_steps(
  mx: Matrix(a),
  from: #(Int, Int),
  taking step: #(Int, Int),
) -> List(Cell(a)) {
  cells_taking_steps_acc(
    mx,
    #(from.0 + step.0, from.1 + step.1),
    step,
    [],
    stop_when_out_of_bounds,
  )
}

fn cells_taking_steps_acc(
  mx: Matrix(a),
  from: #(Int, Int),
  step: #(Int, Int),
  acc: List(Cell(a)),
  until stop: fn(Matrix(a), #(Int, Int)) -> Bool,
) -> List(Cell(a)) {
  use <- bool.guard(when: stop(mx, from), return: acc)
  let assert Ok(x) = get(mx, from.0, from.1)

  cells_taking_steps_acc(
    mx,
    #(from.0 + step.0, from.1 + step.1),
    step,
    list.append(acc, [Cell(from.0, from.1, x)]),
    stop_when_out_of_bounds,
  )
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

pub fn flood_all(mx: Matrix(a)) -> List(List(Cell(a))) {
  do_flood_all(mx, get_all_cells(mx), [])
}

fn do_flood_all(
  mx: Matrix(a),
  remaining: List(Cell(a)),
  acc: List(List(Cell(a))),
) -> List(List(Cell(a))) {
  case remaining {
    [] -> acc
    [first, ..] -> {
      let assert Ok(flooded) = flood(mx, #(first.row, first.column))
      let remaining =
        remaining
        |> list.filter(fn(c) { !list.contains(flooded, c) })

      do_flood_all(mx, remaining, [flooded, ..acc])
    }
  }
}

// Find connected (4-neighbors) region of same values starting
// from a single position.
pub fn flood(mx: Matrix(a), from: #(Int, Int)) -> Result(List(Cell(a)), Nil) {
  use from_val <- result.try(get(mx, from.0, from.1))

  Ok(
    do_flood(
      mx,
      from_val,
      set.from_list([from]),
      set.from_list([Cell(from.0, from.1, from_val)]),
    )
    |> set.to_list,
  )
}

fn do_flood(
  mx: Matrix(a),
  val: a,
  new: set.Set(#(Int, Int)),
  acc: set.Set(Cell(a)),
) {
  case set.to_list(new) {
    [] -> acc
    [first, ..rest] -> {
      let new_neighbors =
        neighbors4_cells(mx, first)
        |> list.filter(fn(x) { x.value == val && !set.contains(acc, x) })
        |> set.from_list

      do_flood(
        mx,
        val,
        set.union(
          set.from_list(rest),
          new_neighbors |> set.map(fn(c) { #(c.row, c.column) }),
        ),
        set.union(acc, new_neighbors),
      )
    }
  }
}

pub fn neighbors4_coords(from: Coord, size: Coord) -> List(Coord) {
  coords_4neighbors
  |> list.filter_map(fn(d) {
    let t = add_coord(from, d)
    case t.0 >= 0 && t.0 <= size.0 && t.1 >= 0 && t.1 <= size.1 {
      True -> Ok(t)
      False -> Error(Nil)
    }
  })
}

pub fn neighbors4_cells(mx: Matrix(a), from: #(Int, Int)) -> List(Cell(a)) {
  coords_4neighbors
  |> list.filter_map(fn(d) {
    let t = add_coord(from, d)
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

pub fn map_by_coord(mx: Matrix(a), with fun: fn(a, Coord) -> b) -> Matrix(b) {
  map(mx, fn(val: a, r: Int, c: Int) { fun(val, #(r, c)) })
}

// Create new Matrix by applying a function on all cells.
pub fn map(mx: Matrix(a), with fun: fn(a, Int, Int) -> b) -> Matrix(b) {
  let content =
    mx.content
    |> dict.map_values(fn(k, v) { fun(v, k.0, k.1) })

  Matrix(mx.size, content)
}

pub fn get_all_cells(mx: Matrix(a)) -> List(Cell(a)) {
  let size = get_size(mx)

  list.range(0, size.0 - 1)
  |> list.flat_map(fn(r) {
    list.range(0, size.1 - 1)
    |> list.map(fn(c) {
      let assert Ok(val) = get(mx, r, c)
      Cell(r, c, val)
    })
  })
}

pub fn get_size(mx: Matrix(a)) -> #(Int, Int) {
  mx.size
}

pub fn get_row(mx: Matrix(a), r: Int) -> Result(List(a), Nil) {
  case r >= mx.size.0 || r < 0 {
    True -> Error(Nil)
    False -> {
      Ok(
        list.range(0, mx.size.1 - 1)
        |> list.map(fn(c) {
          let assert Ok(val) = get(mx, r, c)
          val
        }),
      )
    }
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
  list.range(0, mx.size.0 - 1)
  |> list.each(fn(x) {
    list.range(0, mx.size.1 - 1)
    |> list.each(fn(y) {
      let assert Ok(elem) = mx |> get(x, y)
      io.print(elem |> string.inspect)
      io.print(" ")
    })

    io.println("")
  })
  io.println("")

  mx
}
