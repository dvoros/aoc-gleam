import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import utils

pub fn main() {
  let size = 25
  utils.parse_lines_from_file("input/d09/input.txt", int.parse)
  |> result.unwrap([])
  |> list.window(size + 1)
  |> list.map(fn(x) {
    let rev_x = list.reverse(x)
    let target = list.first(rev_x) |> result.unwrap(-1)
    let rev_x_remaining = list.drop(rev_x, 1)
    let valid =
      rev_x_remaining
      |> list.any(fn(n) {
        case n * 2 == target {
          True -> False
          False ->
            rev_x_remaining
            |> list.contains(target - n)
        }
      })
    #(valid, target)
  })
  |> list.filter(fn(x) { !x.0 })
  |> io.debug
}
