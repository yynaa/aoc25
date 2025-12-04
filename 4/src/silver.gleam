import gleam/result
import gleam/int
import gleam/string
import simplifile
import gleam/list
import gleam/order
import gleamy/red_black_tree_map.{type Map} as map

// --- TYPE ---

type Object {
  Empty
  Roll
}

fn is_roll(o: Object) -> Bool {
  case o {
    Roll -> True
    _ -> False
  }
}

// --- HELPERS ---

fn double_find(m: Map(Int, Map(Int, a)), x: Int, y: Int) -> Result(a, Nil) {
  map.find(m, y) |> result.try(map.find(_, x))
}

fn enumerate(l: List(a)) -> Map(Int, a) {
  enumerate_rec(l, 0)
}

fn enumerate_rec(l: List(a), i: Int) -> Map(Int, a) {
  case l {
    [] -> map.new(int.compare)
    [head, ..tail] -> map.insert(enumerate_rec(tail, i+1), i, head)
  }
}

fn tuple_prepend(l: List(a), p: b) -> List(#(a, b)) {
  case l {
    [] -> []
    [head, ..tail] -> [#(head, p), ..tuple_prepend(tail, p)]
  }
}

// --- PARSING ----

fn grid_to_map(g: List(List(Object))) -> Map(Int, Map(Int, Object)) {
  list.map(g, enumerate) |> enumerate
}

fn parse_object(s: String) -> Object {
  case s {
    "." -> Empty
    "@" -> Roll
    _ -> panic
  }
}

fn parse_line(s: String) -> List(Object) {
  string.to_graphemes(s) |> list.map(parse_object)
}

// --- ALGORITHM ---

fn list_rolls_in_line(m: Map(Int, Object)) -> List(Int) {
  map.fold(m, [], fn(l, p, o) {
    case o {
      Roll -> [p, ..l]
      _ -> l
    }
  })
}

fn list_rolls(m: Map(Int, Map(Int, Object))) -> List(#(Int, Int)) {
  map.fold(m, [], fn(l, y, mm) {
    list.append(l, tuple_prepend(list_rolls_in_line(mm), y))
  })
}

fn bool_to_int(b: Bool) -> Int {
  case b {
    True -> 1
    False -> 0
  }
}

fn is_accessible(m: Map(Int, Map(Int, Object)), pos: #(Int, Int)) -> Bool {
  let x = pos.0
  let y = pos.1
  let n = list.new()
    |> list.prepend(double_find(m, x-1, y-1))
    |> list.prepend(double_find(m, x, y-1))
    |> list.prepend(double_find(m, x+1, y-1))
    |> list.prepend(double_find(m, x-1, y))
    |> list.prepend(double_find(m, x+1, y))
    |> list.prepend(double_find(m, x-1, y+1))
    |> list.prepend(double_find(m, x, y+1))
    |> list.prepend(double_find(m, x+1, y+1))
  let hm = list.map(n, result.unwrap(_, Empty)) |> list.map(is_roll) |> list.fold(0, fn(acc, b) {acc + bool_to_int(b)})
  hm < 4
}

// --- MAIN ---

pub fn main() -> Int {
  let assert Ok(input) = simplifile.read("input.txt")

  let map = string.trim(input) |> string.split("\n") |> list.map(parse_line) |> grid_to_map
  let roll_positions = list_rolls(map)

  list.map(roll_positions, is_accessible(map, _)) |> list.fold(0, fn(acc, b) {acc + bool_to_int(b)})
}
