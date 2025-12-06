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

fn parse_value_line(s: String) -> List(Value) {
  string.split(s, " ") |> remove_empty_strings_in_list |> list.try_map(int.parse) |> result.unwrap([])
}

fn parse_op_line(s: String) -> List(Op) {
  string.split(s, " ") |> remove_empty_strings_in_list |> list.map(parse_op)
}

fn parse_lines(l: List(String)) -> #(List(List(Value)), List(Op)) {
  case l {
    [ops] -> #([], parse_op_line(ops))
    [h, ..tail] -> {
      let p = parse_lines(tail)
      #([parse_value_line(h), ..p.0] , p.1)
    }
    _ -> panic
  }
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
  let transposed_values = data.0 |> list.transpose
  let ops = data.1
  let zipped = list.zip(transposed_values, ops)
  list.map(zipped, calc_line) |> list.fold(0, int.add)
}
