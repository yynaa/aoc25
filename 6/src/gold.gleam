import gleam/result
import gleam/list
import gleam/string
import gleam/int
import simplifile

// --- TYPES ---

type Value = Int
type Op {
  Add
  Mult
}

fn parse_op(s: String) -> Op {
  case s {
    "+" -> Add
    "*" -> Mult
    err -> {
      echo err
      panic
    }
  }
}

// --- PARSING ---

fn remove_empty_strings_in_list(l: List(String)) -> List(String) {
  case l {
    [s, ..t] -> case string.length(s) > 0 {
      True -> [s, ..remove_empty_strings_in_list(t)]
      False -> remove_empty_strings_in_list(t)
    }
    [] -> []
  }
}

fn parse_op_line(s: String) -> List(Op) {
  string.split(s, " ") |> remove_empty_strings_in_list |> list.map(parse_op)
}

fn parse_lines(l: List(String)) -> #(List(List(Value)), List(Op)) {
  let #(values_strings, op_string_wrapped) = list.split(l, list.length(l) - 1)

  let max = list.fold(values_strings, 0, fn(acc, s) {int.max(acc, string.length(s))})

  let splat = values_strings
    |> list.map(string.to_graphemes)
    |> list.map(fn(l) {list.append(l, list.repeat(" ", max - list.length(l)))})
    |> list.transpose
    |> list.chunk(fn(n) {list.all(n, fn(s) {s == " "})})
    |> list.filter(fn(n) {list.all(n, fn(nn) {list.any(nn, fn(s) {s != " "})})})
    |> list.try_map(fn(g) {list.try_map(g, fn(s) {string.join(s, "") |> string.trim |> int.parse})})
    |> result.unwrap([])

  #(splat, list.first(op_string_wrapped) |> result.unwrap("") |> parse_op_line)
}

// --- ALG ---

fn calc_line(l: #(List(Value), Op)) -> Value {
  case l.1 {
    Add -> list.fold(l.0, 0, int.add)
    Mult -> list.fold(l.0, 1, int.multiply)
  }
}

// --- MAIN ---

pub fn main() -> Int {
  let assert Ok(input) = simplifile.read("input.txt")
  let data = string.trim(input) |> string.split("\n") |> parse_lines
  let transposed_values = data.0
  let ops = data.1
  let zipped = list.zip(transposed_values, ops)
  let results = list.map(zipped, calc_line)
  list.fold(results, 0, int.add)
}
