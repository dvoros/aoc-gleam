import gleam/int
import gleam/io
import gleam/list
import gleam/result
import parser
import utils

pub type Robot {
  Robot(p: #(Int, Int), v: #(Int, Int))
}

fn parse_coords() -> parser.Parser(#(Int, Int)) {
  parser.int()
  |> parser.skip(parser.literal(","))
  |> parser.then(parser.int())
}

fn parse_line(line: String) -> Result(Robot, Nil) {
  let assert Ok(#(p, v)) =
    parser.parse_entire(
      line,
      parser.literal("p=")
        |> parser.proceed(parse_coords())
        |> parser.skip(parser.literal(" v="))
        |> parser.then(parse_coords()),
    )
  Ok(Robot(p, v))
}

fn simulate_coord(pos: Int, velocity: Int, seconds: Int, size: Int) -> Int {
  let x = { pos + velocity * seconds } % size
  { x + size } % size
}

fn simulate_robot(r: Robot, seconds: Int, size: #(Int, Int)) -> #(Int, Int) {
  #(
    simulate_coord(r.p.0, r.v.0, seconds, size.0),
    simulate_coord(r.p.1, r.v.1, seconds, size.1),
  )
}

fn count_quadrants(positions: List(#(Int, Int)), size: #(Int, Int)) {
  positions
  |> list.fold(#(0, 0, 0, 0), fn(acc, pos) {
    case pos.0, pos.1 {
      x, y if x < size.0 / 2 && y < size.1 / 2 -> #(
        acc.0 + 1,
        acc.1,
        acc.2,
        acc.3,
      )
      x, y if x > size.0 / 2 && y < size.1 / 2 -> #(
        acc.0,
        acc.1 + 1,
        acc.2,
        acc.3,
      )
      x, y if x < size.0 / 2 && y > size.1 / 2 -> #(
        acc.0,
        acc.1,
        acc.2 + 1,
        acc.3,
      )
      x, y if x > size.0 / 2 && y > size.1 / 2 -> #(
        acc.0,
        acc.1,
        acc.2,
        acc.3 + 1,
      )
      _, _ -> acc
    }
  })
}

pub fn part1(robots: List(Robot), size: #(Int, Int)) {
  let seconds = 100
  let q =
    robots
    |> list.map(simulate_robot(_, seconds, size))
    |> count_quadrants(size)
    |> io.debug
  io.debug(q.0 * q.1 * q.2 * q.3)
}

fn draw(coords: List(#(Int, Int)), size: #(Int, Int)) {
  list.range(1, size.1)
  |> list.each(fn(y) {
    list.range(1, size.0)
    |> list.each(fn(x) {
      let count = list.count(coords, fn(c) { c == #(x, y) })
      case count {
        0 -> io.print(" ")
        _ -> io.print(int.to_string(count))
      }
    })
    io.println("")
  })
  io.println("")
}

pub fn part2(robots: List(Robot), size: #(Int, Int)) {
  list.range(1, 100)
  |> list.each(fn(x) {
    let x = 33 + x * 101
    io.debug(x)
    io.println("round " <> int.to_string(x) <> ":")
    robots
    |> list.map(simulate_robot(_, x, size))
    |> draw(size)
  })
}

pub fn main() {
  let robots =
    utils.parse_lines_from_file("input/y2024/d14/input.txt", parse_line)
    |> result.unwrap([])

  let size = #(101, 103)
  let _ = part1(robots, size)
  let _ = part2(robots, size)
}
