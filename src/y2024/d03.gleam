import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/pair
import gleam/regexp
import gleam/result
import utils

pub type Match {
  Do
  Dont
  Num(Int)
}

fn parse_line_2(line: String) {
  let assert Ok(re) =
    regexp.from_string(
      "mul\\(([0-9]{1,3}),([0-9]{1,3})\\)|do\\(\\)|don't\\(\\)",
    )
  let matches = regexp.scan(re, line)

  Ok(
    matches
    |> list.map(fn(match) {
      case match.content {
        "do()" -> Do
        "don't()" -> Dont
        _ -> {
          let num =
            match.submatches
            |> list.map(fn(submatch) {
              submatch |> option.unwrap("0") |> int.parse |> result.unwrap(0)
            })
            |> list.reduce(int.multiply)
            |> result.unwrap(0)
          Num(num)
        }
      }
    }),
  )
}

fn parse_line(line: String) {
  let assert Ok(re) = regexp.from_string("mul\\(([0-9]{1,3}),([0-9]{1,3})\\)")
  let matches = regexp.scan(re, line)

  Ok(
    matches
    |> list.map(fn(match) {
      match.submatches
      |> list.map(fn(submatch) {
        submatch |> option.unwrap("0") |> int.parse |> result.unwrap(0)
      })
      |> list.reduce(int.multiply)
      |> result.unwrap(0)
    })
    |> list.reduce(int.add),
  )
}

pub fn main() {
  //   let reports =
  //     utils.parse_lines_from_file("input/y2024/d03/example.txt", parse_line)
  //     |> result.unwrap([])
  //     |> list.map(result.unwrap(_, 0))
  //     |> list.reduce(int.add)
  //     |> io.debug

  utils.parse_lines_from_file("input/y2024/d03/example2.txt", parse_line_2)
  |> result.unwrap([])
  |> list.reduce(list.append)
  |> result.unwrap([])
  |> list.fold(#(True, 0), fn(acc, m) {
    case m {
      Do -> #(True, acc.1)
      Dont -> #(False, acc.1)
      Num(n) ->
        case acc.0 {
          True -> #(acc.0, acc.1 + n)
          False -> acc
        }
    }
  })
  |> pair.second
  |> io.debug
}
