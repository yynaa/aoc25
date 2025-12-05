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
        True -> option.Some(Tree(add_range_to_tree(left, v), tv, right))
        False -> case vs - te > 1 {
          True -> option.Some(Tree(left, tv, add_range_to_tree(right, v)))
          False -> option.Some(Tree(left, #(int.min(ts, vs), int.max(te, ve)), right))
        }
      }

      next
    }
  }
}

fn flatten_tree(ot: Option(Tree)) -> List(Range) {
  case ot {
    option.None -> []
    option.Some(Tree(left, r, right)) -> [r] |> list.append(flatten_tree(left)) |> list.append(flatten_tree(right))
  }
}

fn sort_by_start(l: List(Range)) -> List(Range) {
  list.sort(l, fn(a,b){int.compare(a.0, b.0)})
}

fn merge_two_by_two(l: List(Range)) -> List(Range) {
  case l {
    [a, b, ..t] -> {
      let a_st = a.0
      let a_en = a.1
      let b_st = b.0
      let b_en = b.1

      case b_st - a_en <= 1 && a_st - b_en <= 1 {
        True -> {
          [#(int.min(a_st, b_st), int.max(a_en, b_en)), ..merge_two_by_two(t)]
        }
        False -> [a, ..merge_two_by_two([b, ..t])]
      }
    }
    el -> el
  }
}

fn sort_and_merge_until_stable(l: List(Range)) -> List(Range) {
  let n = l |> sort_by_start |> merge_two_by_two
  case n == l {
    True -> n
    False -> sort_and_merge_until_stable(n)
  }
}

fn get_length(r: Range) -> Int {
  r.1 - r.0 + 1
}

// --- MAIN ---

pub fn main() -> Int {
  let assert Ok(input) = simplifile.read("input.txt")
  let input_middle_split = string.trim(input) |> string.split("\n\n")
  let parsed_inputs = case input_middle_split {
    [input_ranges, _] -> {
      #(
        string.split(input_ranges, "\n") |> list.map(parse_range),
        []// string.split(input_ids, "\n") |> list.map(parse_id)
      )
    }
    _ -> panic
  }

  let fresh_set = list.fold(parsed_inputs.0, option.None, add_range_to_tree)

  let flattened = flatten_tree(fresh_set)
    |> sort_and_merge_until_stable

  flattened
    |> list.map(get_length)
    |> list.fold(0, int.add)
}
