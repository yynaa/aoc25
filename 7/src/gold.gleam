import gleam/result
import gleam/list
import gleam/string
import simplifile
import gleam/dict.{type Dict}

type Object {
  Start
  Splitter
}

type Line = Dict(Int, Object)

fn parse_line(s: String, i: Int) -> Line {
  case s {
    "" -> dict.new()
    "S" <> r -> dict.insert(parse_line(r, i+1), i+1, Start)
    "^" <> r -> dict.insert(parse_line(r, i+1), i+1, Splitter)
    "." <> r -> parse_line(r, i+1)
    _ -> panic
  }
}

fn increase_int(d: Dict(a, Int), k: a, p: Int) -> Dict(a, Int) {
  let ov = dict.get(d, k) |> result.unwrap(0)
  dict.insert(d, k, ov+p)
}

fn beam_iterate(windows: List(Line), pos: Dict(Int, Int)) -> Int {
  case windows {
    [] -> 0
    [h, ..t] -> {
      let f = dict.fold(pos, #(dict.new(), dict.new()), fn(acc, k, v) {
        case dict.get(h, k) {
          Error(_) -> #(increase_int(acc.0, k, v), acc.1)
          Ok(o) -> case o {
            Splitter -> #(increase_int(acc.0, k-1, v) |> increase_int(k+1, v), increase_int(acc.1, k, v))
            _ -> panic
          }
        }
      })
      dict.fold(f.1, 0, fn(acc, _, v){acc+v}) + beam_iterate(t, f.0)
    }
  }
}

fn beam_start(windows: List(Line)) -> Int {
  case windows {
    [h, ..t] -> 1 + beam_iterate(t, dict.fold(h, dict.new(), fn(acc, k, v) {case v {
      Start -> dict.insert(acc, k, 1)
      _ -> acc
    }}))
    _ -> panic
  }
}

pub fn main() -> Int {
  let assert Ok(input) = simplifile.read("input.txt")
  let lines = string.trim(input) |> string.split("\n")
  let parsed = list.map(lines, parse_line(_, 0))

  beam_start(parsed)
}
