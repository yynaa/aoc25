import gleam/result
import gleam/string
import simplifile
import gleam/list
import gleam/int
import gleam/float

fn list_to_int(i: List(Int)) -> Int {
  case i {
    [head, ..tail] -> head * float.round(result.unwrap(int.power(10, int.to_float(list.length(tail))), -1.)) + list_to_int(tail)
    _ -> 0
  }
}

fn explore(best: List(Int), c: Int) -> List(Int) {
  case list.length(best) < 12 {
    True -> [c, ..best]
    False -> case list.first(best) {
      Error(_) -> panic
      Ok(first) -> case c >= first {
        True -> [c, ..remove_first_increase(best)]
        False -> best
      }
    }
  }
}

fn remove_first_increase(l: List(Int)) -> List(Int) {
  case l {
    [a, b, ..tail] -> case b > a {
      True -> [b, ..tail]
      False -> [a, ..remove_first_increase([b, ..tail])]
    }
    [_] -> []
    _ -> panic
  }
}

fn parser(s: String) -> List(Int) {
  string.to_graphemes(s) |> list.try_map(int.parse) |> result.unwrap([])
}

pub fn main() -> Int {
  let assert Ok(input) = simplifile.read("input.txt")
  let battery_packs = string.trim(input)
    |> string.split("\n")
    |> list.map(parser)

  let bests = list.map(battery_packs, list.fold_right(_, [], explore))
    |> list.map(list_to_int)

  list.fold(bests, 0, int.add)
}
