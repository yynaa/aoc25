import gleam/result
import gleam/string
import simplifile
import gleam/list
import gleam/int
import gleam/order

fn tuple_to_int(i: #(Int, Int)) -> Int {
  i.0 * 10 + i.1
}

fn explore(best: #(Int, Int), c: Int) -> #(Int, Int) {
  let a = best.0
  let b = best.1
  case b == -1 {
    True -> #(a, c)
    False -> case a == -1 {
      True -> #(c, b)
      False -> case int.compare(c, a) {
        order.Gt -> case int.compare(a, b) {
          order.Gt -> #(c, a)
          _ -> #(c, b)
        }
        order.Eq -> case int.compare(a, b) {
          order.Gt -> #(c, a)
          _ -> #(c, b)
        }
        order.Lt -> best
      }
    }
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

  let bests = list.map(battery_packs, list.fold_right(_, #(-1, -1), explore))
    |> list.map(tuple_to_int)

  list.fold(bests, 0, int.add)
}
