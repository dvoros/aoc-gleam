import gleam/dict
import gleam/function
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import utils

pub type Matrix(a) {
  Matrix(content: dict.Dict(Int, dict.Dict(Int, a)))
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

pub fn neighbors8(mx: Matrix(a), r: Int, c: Int) -> List(a) {
  [#(-1, -1), #(-1, 0), #(-1, 1), #(0, -1), #(0, 1), #(1, -1), #(1, 0), #(1, 1)]
  |> list.filter_map(fn(p) { get(mx, r + p.0, c + p.1) })
}

pub fn map(mx: Matrix(a), with fun: fn(a, Int, Int) -> a) -> Matrix(a) {
  mx.content
  |> dict.map_values(fn(r, row) {
    row
    |> dict.map_values(fn(c, val) { fun(val, r, c) })
  })
  |> new_from_dict_dict
}

// pub fn set(mx: Matrix(a), r: Int, c: Int, value: a) -> Matrix(a) {
//   todo
// }

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
