import gleam/float
import gleam/result
import gleam/list
import gleam/string
import gleam/int
import simplifile

type Range = #(Int, Int)

fn parse_range(s: String) -> #(Int, Int) {
  let l = string.split(s, "-") |> list.try_map(int.parse) |> result.unwrap([])
  #(list.first(l) |> result.unwrap(0), list.last(l) |> result.unwrap(0))
}

fn get_invalids(r: Range) -> List(Int) {
  smallest_invalid_subdenom(r.0) |> get_all_invalids_until(r.1)
}

fn subdenom_to_num(n: Int) -> Int {
  let s = int.to_string(n)
  let assert Ok(parsed) = int.parse(s <> s)
  parsed
}

fn smallest_invalid_subdenom(n: Int) -> Int {
  let s = int.to_string(n)
  let length = string.length(s)
  case int.is_even(length) {
    True -> {
      let assert Ok(middle_float) = int.to_float(length) |> float.divide(2.)
      let middle = float.floor(middle_float) |> float.round
      let s_begin = string.drop_end(s, middle)
      let assert Ok(subdenom) = int.parse(s_begin)
      let smallest_num = subdenom_to_num(subdenom)
      case smallest_num >= n {
        True -> subdenom
        False -> subdenom + 1
      }
    }
    False -> {
      let assert Ok(pow) = int.power(10, int.to_float(length))
      smallest_invalid_subdenom(float.round(pow))
    }
  }
}

fn get_all_invalids_until(current_subdenom: Int, until: Int) -> List(Int) {
  let current_num = subdenom_to_num(current_subdenom)
  case current_num > until {
    True -> []
    False -> [current_num, ..get_all_invalids_until(current_subdenom+1, until)]
  }
}



pub fn main() -> Int {
  let assert Ok(input) = simplifile.read("input.txt")
  let ranges = string.trim(input) |> string.split(",") |> list.map(parse_range)
  let invalids = list.map(ranges, get_invalids) |> list.map(list.fold(_, 0, int.add)) |> list.fold(0, int.add)
  invalids
}
