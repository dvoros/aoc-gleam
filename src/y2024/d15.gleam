import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/set
import gleam/string
import matrix
import utils

pub fn gps_sum(boxes: List(Box)) -> Int {
  let assert Ok(res) =
    boxes
    |> list.map(fn(b) {
      let assert Ok(first) = b.coords |> list.first
      first.0 * 100 + first.1
    })
    |> list.reduce(int.add)

  res
}

pub type Warehouse {
  Warehouse(
    size: #(Int, Int),
    boxes: List(Box),
    walls: set.Set(#(Int, Int)),
    pos: #(Int, Int),
  )
}

pub type Box {
  Box(coords: List(#(Int, Int)))
}

fn has_wall_at(wh: Warehouse, pos: #(Int, Int)) -> Bool {
  set.contains(wh.walls, pos)
}

fn box_at(wh: Warehouse, pos: #(Int, Int)) -> option.Option(Box) {
  let boxes_at_pos =
    wh.boxes
    |> list.filter(fn(b) { list.any(b.coords, fn(coord) { coord == pos }) })

  case boxes_at_pos {
    [] -> None
    [box] -> Some(box)
    _ -> panic as "multiple boxes on the same coordinates"
  }
}

fn others_pushed_by_box(
  wh: Warehouse,
  box: Box,
  dir: #(Int, Int),
) -> #(List(Box), Bool) {
  let pushed_coords =
    box.coords
    |> list.map(fn(c) { #(c.0 + dir.0, c.1 + dir.1) })

  let wall_in_the_way =
    pushed_coords
    |> list.any(has_wall_at(wh, _))

  case wall_in_the_way {
    True -> #([], False)
    False -> {
      let touching_boxes =
        pushed_coords
        |> list.filter_map(fn(c) {
          case box_at(wh, c) {
            None -> Error(Nil)
            Some(b) ->
              case b == box {
                True -> Error(Nil)
                False -> Ok(b)
              }
          }
        })

      let transitive_results =
        touching_boxes
        |> list.map(others_pushed_by_box(wh, _, dir))

      case transitive_results |> list.any(fn(r) { r.1 == False }) {
        True -> #([], False)
        False -> {
          let transitive_boxes =
            transitive_results
            |> list.fold([], fn(acc, res) { list.append(acc, res.0) })
          #(list.append(transitive_boxes, touching_boxes), True)
        }
      }
    }
  }
}

fn push_box(wh: Warehouse, box: Box, dir: #(Int, Int)) -> #(Warehouse, Bool) {
  let wall_in_the_way =
    box.coords
    |> list.any(fn(c) {
      let pushed_coord = #(c.0 + dir.0, c.1 + dir.1)
      has_wall_at(wh, pushed_coord)
    })
  case wall_in_the_way {
    True -> #(wh, False)
    False -> {
      case others_pushed_by_box(wh, box, dir) {
        #(_, False) -> #(wh, False)
        #(others, True) -> {
          let all_pushed_boxes = [box, ..others]

          let new_boxes =
            wh.boxes
            |> list.map(fn(b) {
              case list.contains(all_pushed_boxes, b) {
                False -> b
                True ->
                  Box(
                    coords: b.coords
                    |> list.map(fn(c) { #(c.0 + dir.0, c.1 + dir.1) }),
                  )
              }
            })

          #(Warehouse(..wh, boxes: new_boxes), True)
        }
      }
    }
  }
}

fn apply_move(wh: Warehouse, move: String) -> Warehouse {
  let delta = case move {
    "^" -> #(-1, 0)
    ">" -> #(0, 1)
    "v" -> #(1, 0)
    "<" -> #(0, -1)
    _ -> panic as "unexpected move"
  }
  let new_pos = #(wh.pos.0 + delta.0, wh.pos.1 + delta.1)

  case has_wall_at(wh, new_pos), box_at(wh, new_pos) {
    True, _ -> wh
    False, None -> Warehouse(..wh, pos: new_pos)
    False, Some(box) -> {
      case push_box(wh, box, delta) {
        #(_, False) -> wh
        #(wh, True) -> Warehouse(..wh, pos: new_pos)
      }
    }
  }
}

fn parse_warehouse(mx: matrix.Matrix(String), start: #(Int, Int)) -> Warehouse {
  let cells = mx |> matrix.get_all_cells

  let boxes =
    cells
    |> list.filter_map(fn(c) {
      case c.value {
        "O" -> Ok(Box(coords: [#(c.row, c.column)]))
        _ -> Error(Nil)
      }
    })

  let walls =
    cells
    |> list.filter(fn(c) { c.value == "#" })
    |> list.map(matrix.cell_coord)
    |> set.from_list

  let size = matrix.get_size(mx)

  Warehouse(size, boxes, walls, start)
}

fn solve_warehouse(wh: Warehouse, moves: String) -> Int {
  let res =
    moves
    |> string.to_graphemes
    |> list.fold(wh, apply_move)

  res.boxes |> gps_sum
}

fn part1(mx: matrix.Matrix(String), start: #(Int, Int), moves: String) {
  parse_warehouse(mx, start)
  |> solve_warehouse(moves)
  |> io.debug
}

fn widen_coord(c: #(Int, Int)) -> List(#(Int, Int)) {
  [#(c.0, c.1 * 2), #(c.0, c.1 * 2 + 1)]
}

fn widen_warehouse(wh: Warehouse) -> Warehouse {
  Warehouse(
    size: #(wh.size.0, wh.size.1 * 2),
    boxes: wh.boxes
      |> list.map(fn(b) {
        Box(
          b.coords
          |> list.flat_map(widen_coord),
        )
      }),
    walls: wh.walls
      |> set.to_list
      |> list.flat_map(widen_coord)
      |> set.from_list,
    pos: #(wh.pos.0, wh.pos.1 * 2),
  )
}

fn part2(mx: matrix.Matrix(String), start: #(Int, Int), moves: String) {
  parse_warehouse(mx, start)
  |> widen_warehouse
  |> solve_warehouse(moves)
  |> io.debug
}

pub fn draw(wh: Warehouse) -> Warehouse {
  list.range(0, wh.size.0 - 1)
  |> list.each(fn(row) {
    list.range(0, wh.size.1 - 1)
    |> list.each(fn(col) {
      let c = #(row, col)
      let char_to_print = case wh.pos == c, set.contains(wh.walls, c) {
        True, _ -> "@"
        _, True -> "#"
        False, False -> {
          case box_at(wh, #(row, col)) {
            None -> "."
            Some(box) -> {
              case box.coords {
                [coord, ..] if coord == c -> "["
                _ -> "]"
              }
            }
          }
        }
      }

      io.print(char_to_print)
    })
    io.println("")
  })
  io.println("")
  wh
}

pub fn main() {
  let assert Ok([mx, moves]) =
    utils.read_file_split_by("input/y2024/d15/input.txt", "\n\n")

  let mx =
    mx
    |> string.split("\n")
    |> matrix.new_from_string_list

  let assert Ok(start) =
    mx
    |> matrix.filter(fn(v, _r, _c) { v == "@" })
    |> list.map(matrix.cell_coord)
    |> list.first

  let mx =
    mx
    |> matrix.set(start.0, start.1, ".")

  let moves = moves |> string.replace("\n", "")

  let _ = part1(mx, start, moves)
  let _ = part2(mx, start, moves)
}
