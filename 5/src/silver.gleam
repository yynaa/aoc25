import gleam/result
import gleam/int
import gleam/string
import simplifile
import gleam/list
import gleam/option.{type Option}

// --- TYPES ---

type Range = #(Int, Int)

type Tree {
  Tree(Option(Tree), Range, Option(Tree))
}

fn tree_new(v: Range) -> Tree {
  Tree(option.None, v, option.None)
}

// --- PARSING ---

fn parse_range(s: String) -> Range {
  case string.split(s, "-") {
    [start, end] -> #(int.parse(start) |> result.unwrap(-1), int.parse(end) |> result.unwrap(-1))
    _ -> panic
  }
}

fn parse_id(s: String) -> Int {
  int.parse(s) |> result.unwrap(-1)
}

fn add_range_to_tree(ot: Option(Tree), v: Range) -> Option(Tree) {
  case ot {
    option.None -> option.Some(tree_new(v))
    option.Some(Tree(left, tv, right)) -> {
      // COMPARE
      let ts = tv.0
      let te = tv.1
      let vs = v.0
      let ve = v.1

      let next = case ts - ve > 1 {
        True -> Tree(add_range_to_tree(left, v), tv, right)
        False -> case vs - te > 1 {
          True -> Tree(left, tv, add_range_to_tree(right, v))
          False -> Tree(left, #(int.min(ts, vs), int.max(te, ve)), right)
        }
      }

      option.Some(next)
    }
  }
}

fn is_id_fresh(ot: Option(Tree), v: Int) -> Bool {
  case ot {
    option.None -> False
    option.Some(Tree(left, tv, right)) -> {
      let ts = tv.0
      let te = tv.1
      case v > te {
        True -> is_id_fresh(right, v)
        False -> case v < ts {
          True -> is_id_fresh(left, v)
          False -> True
        }
      }
    }
  }
}

// --- MAIN ---

fn bool_to_int(b: Bool) -> Int {
  case b {
    True -> 1
    False -> 0
  }
}

pub fn main() -> Int {
  let assert Ok(input) = simplifile.read("input.txt")
  let input_middle_split = string.trim(input) |> string.split("\n\n")
  let parsed_inputs = case input_middle_split {
    [input_ranges, input_ids] -> {
      #(
        string.split(input_ranges, "\n") |> list.map(parse_range),
        string.split(input_ids, "\n") |> list.map(parse_id)
      )
    }
    _ -> panic
  }

  let fresh_set = list.fold(parsed_inputs.0, option.None, add_range_to_tree)
  let fresh_ids = list.map(parsed_inputs.1, is_id_fresh(fresh_set, _))

  list.fold(fresh_ids, 0, fn(acc, b) {acc + bool_to_int(b)})
}
