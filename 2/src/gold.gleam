import gleam/float
import gleam/result
import gleam/list
import gleam/string
import gleam/int
import simplifile
import gleam/set.{type Set}

type Range = #(Int, Int)

fn parse_range(s: String) -> #(Int, Int) {
  let l = string.split(s, "-") |> list.try_map(int.parse) |> result.unwrap([])
  #(list.first(l) |> result.unwrap(0), list.last(l) |> result.unwrap(0))
}

fn get_invalids(r: Range) -> Set(Int) {
  let patterns = int.to_string(r.1) |> string.length
  get_invalids_until_two(r, patterns)
}

fn get_invalids_until_two(r: Range, n: Int) -> Set(Int) {
  case n {
    1 -> set.new()
    _ -> smallest_invalid_subdenom(r.0, n) |> get_all_invalids_until(r.1, n) |> set.union(get_invalids_until_two(r, n-1))
  }
}

fn concat_to_itself_n_times(s: String, n: Int) -> String {
  case n {
    1 -> s
    _ -> s <> concat_to_itself_n_times(s, n-1)
  }
}

fn subdenom_to_num(n: Int, n_patterns: Int) -> Int {
  let s = int.to_string(n)
  let assert Ok(parsed) = concat_to_itself_n_times(s, n_patterns) |> int.parse
  parsed
}

fn smallest_invalid_subdenom(n: Int, n_patterns: Int) -> Int {
  let s = int.to_string(n)
  let length = string.length(s)
  case length % n_patterns == 0 {
    True -> {
      let assert Ok(end_float) = int.to_float(length) |> float.divide(int.to_float(n_patterns))
      let end = float.floor(end_float) |> float.round
      let s_begin = string.slice(s, 0, end)
      let assert Ok(subdenom) = int.parse(s_begin)
      let smallest_num = subdenom_to_num(subdenom, n_patterns)
      case smallest_num >= n {
        True -> subdenom
        False -> subdenom + 1
      }
    }
    False -> {
      let assert Ok(pow) = int.power(10, int.to_float(length))
      smallest_invalid_subdenom(float.round(pow), n_patterns)
    }
  }
}

fn get_all_invalids_until(current_subdenom: Int, until: Int, n_patterns: Int) -> Set(Int) {
  let current_num = subdenom_to_num(current_subdenom, n_patterns)
  case current_num > until {
    True -> set.new()
    False -> set.insert(get_all_invalids_until(current_subdenom+1, until, n_patterns), current_num)
  }
}



pub fn main() -> Int {
  let assert Ok(input) = simplifile.read("input.txt")
  let ranges = string.trim(input) |> string.split(",") |> list.map(parse_range)
  let invalids = list.map(ranges, get_invalids) |> list.map(set.fold(_, 0, int.add)) |> list.fold(0, int.add)
  invalids
}
