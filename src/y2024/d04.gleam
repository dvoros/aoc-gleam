import gleam/int
import gleam/io
import gleam/list
import gleam/string
import matrix
import utils

pub fn part1(mx: matrix.Matrix(String)) {
  list.concat([
    matrix.cols(mx),
    matrix.rows(mx),
    matrix.diagonals_major(mx),
    matrix.diagonals_minor(mx),
  ])
  |> list.flat_map(fn(x) {
    let str = string.concat(x)
    [str, string.reverse(str)]
  })
  |> list.map(fn(str) {
    let x =
      string.split(str, "XMAS")
      |> list.length
    x - 1
  })
  |> list.reduce(int.add)
  |> io.debug
}

fn x_xhapes(mx: matrix.Matrix(String)) {
  let size = matrix.get_size(mx)
  list.range(0, size.0 - 3)
  |> list.flat_map(fn(row) {
    list.range(0, size.1 - 3)
    |> list.map(fn(col) {
      let major =
        mx
        |> matrix.cells_taking_steps(#(row - 1, col - 1), #(1, 1))
        |> list.take(3)
        |> list.map(matrix.cell_value)

      let minor =
        mx
        |> matrix.cells_taking_steps(#(row - 1, col + 3), #(1, -1))
        |> list.take(3)
        |> list.map(matrix.cell_value)

      [major |> string.concat, minor |> string.concat]
    })
  })
}

pub fn part2(mx: matrix.Matrix(String)) {
  x_xhapes(mx)
  |> list.filter(list.all(_, fn(diag) {
    [diag, string.reverse(diag)]
    |> list.any(fn(str) { str == "MAS" })
  }))
  |> list.length
  |> io.debug
}

pub fn main() {
  let assert Ok(lines) = utils.read_lines_from_file("input/y2024/d04/input.txt")
  let mx = matrix.new_from_string_list(lines)

  let _ = mx |> part1
  let _ = mx |> part2
}
