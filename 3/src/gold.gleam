import gleam/result
import gleam/string
import simplifile
import gleam/list
import gleam/int
import gleam/order
import gleam/float

fn list_to_int(i: List(Int)) -> Int {
  case i {
    [head, ..tail] -> head * float.round(result.unwrap(int.power(10, int.to_float(list.length(tail))), -1.)) + list_to_int(tail)
    _ -> 0
  }
}

fn fill(v: a, n: Int) -> List(a) {
  case n <= 0 {
    True -> []
    False -> [v, ..fill(v, n-1)]
  }
}

fn explore(best: List(Int), c: Int) -> List(Int) {
  case list.contains(best, -1) {
    True -> list.reverse(best) |> fill_empty_in_best(c) |> list.reverse
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

fn fill_empty_in_best(best: List(Int), c: Int) -> List(Int) {
  case best {
    [-1, ..tail] -> [c, ..tail]
    [head, ..tail] -> [head, ..fill_empty_in_best(tail, c)]
    _ -> panic
  }
}

pub fn main() -> Int {
  let assert Ok(input) = simplifile.read("input.txt")
  let battery_packs = string.trim(input)
    |> string.split("\n")
    |> list.map(string.to_graphemes)
    |> list.map(list.try_map(_, int.parse))
    |> list.map(result.unwrap(_, []))

  let bests = list.map(battery_packs, list.fold_right(_, fill(-1, 12), explore))
    |> list.map(list_to_int)

  list.fold(bests, 0, int.add)
}
