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

fn beam_iterate(windows: List(Line), pos: Dict(Int, Nil)) -> Int {
  case windows {
    [] -> 0
    [h, ..t] -> {
      let f = dict.fold(pos, #(dict.new(), dict.new()), fn(acc, k, _) {
        case dict.get(h, k) {
          Error(_) -> #(dict.insert(acc.0, k, Nil), acc.1)
          Ok(o) -> case o {
            Splitter -> #(dict.insert(acc.0, k-1, Nil) |> dict.insert(k+1, Nil), dict.insert(acc.1, k, Nil))
            _ -> panic
          }
        }
      })
      dict.size(f.1) + beam_iterate(t, f.0)
    }
  }
}

fn beam_start(windows: List(Line)) -> Int {
  case windows {
    [h, ..t] -> beam_iterate(t, dict.fold(h, dict.new(), fn(acc, k, v) {case v {
      Start -> dict.insert(acc, k, Nil)
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
