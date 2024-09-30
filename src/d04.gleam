import gleam/dict
import gleam/int
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

fn is_valid_part1(pairs: List(#(String, String))) -> Bool {
  has_all_required(pairs)
}

fn get_int(d: dict.Dict(String, String), field: String) -> Int {
  dict.get(d, field)
  |> result.unwrap("")
  |> int.parse
  |> result.unwrap(0)
}

fn valid_byr(d: dict.Dict(String, String)) -> Bool {
  let num = get_int(d, "byr")
  num >= 1920 && num <= 2002
}

fn valid_iyr(d: dict.Dict(String, String)) -> Bool {
  let num = get_int(d, "iyr")
  num >= 2010 && num <= 2020
}

fn valid_eyr(d: dict.Dict(String, String)) -> Bool {
  let num = get_int(d, "eyr")
  num >= 2020 && num <= 2030
}

fn valid_hgt(d: dict.Dict(String, String)) -> Bool {
  let hgt = dict.get(d, "hgt") |> result.unwrap("")
  let num =
    string.slice(hgt, 0, string.length(hgt) - 2)
    |> int.parse
    |> result.unwrap(0)
  case string.ends_with(hgt, "cm"), string.ends_with(hgt, "in") {
    True, False -> num >= 150 && num <= 193
    False, True -> num >= 59 && num <= 76
    _, _ -> False
  }
}

fn valid_hcl(d: dict.Dict(String, String)) -> Bool {
  let hcl = dict.get(d, "hcl") |> result.unwrap("")
  let assert Ok(re) = regex.from_string("^#[0-9a-f]{6}$")
  regex.check(re, hcl)
}

fn valid_ecl(d: dict.Dict(String, String)) -> Bool {
  case dict.get(d, "ecl") |> result.unwrap("") {
    "amb" | "blu" | "brn" | "gry" | "grn" | "hzl" | "oth" -> True
    _ -> False
  }
}

fn valid_pid(d: dict.Dict(String, String)) -> Bool {
  let pid = dict.get(d, "pid") |> result.unwrap("")
  let assert Ok(re) = regex.from_string("^[0-9]{9}$")
  regex.check(re, pid)
}

fn is_valid_part2(pairs: List(#(String, String))) -> Bool {
  let d = dict.from_list(pairs)
  pairs |> io.debug
  has_all_required(pairs)
  && valid_byr(d) |> io.debug()
  && valid_iyr(d) |> io.debug()
  && valid_eyr(d) |> io.debug()
  && valid_hgt(d) |> io.debug()
  && valid_hcl(d) |> io.debug()
  && valid_ecl(d) |> io.debug()
  && valid_pid(d) |> io.debug()
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
    pairs |> is_valid_part2
  })
  |> list.count(fn(x) { x })
  |> io.debug
}
