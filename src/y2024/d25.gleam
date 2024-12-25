import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/string
import matrix
import utils

pub fn main() {
  let assert Ok(mxs) =
    utils.parse_empty_line_separated_blocks_from_file(
      "input/y2024/d25/input.txt",
      fn(block: String) {
        Ok(
          block
          |> string.split("\n")
          |> matrix.new_from_string_list,
        )
      },
    )

  let #(keys, locks) =
    mxs
    |> list.map(fn(mx) {
      let is_key = matrix.get(mx, 0, 0) == Ok(".")
      #(
        is_key,
        mx
          |> matrix.cols
          |> list.map(fn(col) {
            let res = col |> list.count(fn(x) { x == "#" })
            res - 1
          }),
      )
    })
    |> list.partition(pair.first)

  keys
  |> list.map(fn(key) {
    let key = key.1
    locks
    |> list.filter(fn(lock) {
      let lock = lock.1
      list.zip(key, lock)
      |> list.all(fn(col) { col.0 + col.1 <= 5 })
    })
    |> list.length
  })
  |> list.reduce(int.add)
  |> io.debug
}
