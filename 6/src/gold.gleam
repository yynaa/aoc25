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

  let splat = parsing_iterate(values_strings)

  #(splat, list.first(op_string_wrapped) |> result.unwrap("") |> parse_op_line)
}

// --- GOLD PARSING ---

fn parsing_iterate(l: List(String)) -> List(List(Value)) {
  let so = list.map(l, get_number_until_ws_post_number)
  let so_values = list.map(so, fn(v) {v.0})
  // max of characters in parsed values
  let max = list.fold(so_values, 0, fn(acc, t) {int.max(acc, string.length(t))})
  // fixed length values
  let so_values_fixed = list.map(so_values, fn(t) {postpend_ws(t, max - string.length(t))})
  // remainders
  let so_rests = list.map(so, fn(v) {string.drop_start(v.1, max - string.length(v.0))})

  // transposing alg
  let assert Ok(correct_values) =
    list.map(so_values_fixed, string.to_graphemes)
    |> list.transpose
    |> list.map(fn(l) {string.join(l, "") |> string.trim})
    |> list.try_map(int.parse)

  let assert Ok(rests_length_helper) = list.first(so_rests)
  case string.length(rests_length_helper) {
    0 -> [correct_values]
    _ -> [correct_values, ..parsing_iterate(so_rests)]
  }
}

fn postpend_ws(s: String, l: Int) -> String {
  case l {
    0 -> s
    n -> postpend_ws(s, n-1) <> " "
  }
}

fn get_number_until_ws_post_number(gr: String) -> #(String, String) {
  case gr {
    " " <> rest -> {
      let next = get_number_until_ws_post_number(rest)
      #(" " <> next.0, next.1)
    }
    rest -> get_number_until_ws(rest)
  }
}

fn get_number_until_ws(gr: String) -> #(String, String) {
  case string.split_once(gr, " ") {
    Ok(v) -> v
    Error(_) -> #(gr, "")
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
  let transposed_values = data.0
  let ops = data.1
  let zipped = list.zip(transposed_values, ops)
  let results = list.map(zipped, calc_line)
  list.fold(results, 0, int.add)
}
