import gleam/io
import gleam/list
import gleam/regex
import gleam/result
import gleam/string
import utils

pub type Height {
  Inch(n: Int)
  Centimeter(n: Int)
}

pub type Passport {
  Valid(
    byr: Int,
    iyr: Int,
    eyr: Int,
    hgt: Height,
    ecl: String,
    pid: String,
    cid: String,
  )
  Invalid
}

fn has_all_required(pairs: List(#(String, String))) -> Bool {
  list.all(["byr", "iyr", "eyr", "hgt", "hcl", "ecl", "pid"], fn(x) {
    list.filter(pairs, fn(p) { p.0 == x })
    |> list.length
    == 1
  })
}

fn is_valid(pairs: List(#(String, String))) -> Bool {
  has_all_required(pairs)
}

pub fn main() {
  let blocks =
    utils.parse_empty_line_separated_blocks_from_file(
      "input/d04/input.txt",
      fn(x) { Ok(x) },
    )

  let assert Ok(re) = regex.from_string("[ \n]")

  list.map(result.unwrap(blocks, []), fn(b) {
    let pairs =
      regex.split(re, b)
      |> list.map(fn(x) {
        string.split_once(x, ":") |> result.unwrap(#("", ""))
      })
    pairs |> is_valid
  })
  |> list.count(fn(x) { x })
  |> io.debug
}
