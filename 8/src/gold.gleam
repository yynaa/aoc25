import gleam/bool
import gleam/float
import gleam/result
import gleam/string
import gleam/list
import gleam/int
import gleam/dict.{type Dict}
import gleam/option.{type Option, None, Some}
import simplifile

type Pos = #(Int, Int, Int)
type Sort = #(Pos, Pos, Float)
type Graph = Dict(Pos, Option(Int))

fn parse_line(s: String) -> Pos {
  case string.split(s, ",") |> list.try_map(int.parse) {
    Ok([a,b,c]) -> #(a,b,c)
    _ -> panic
  }
}

fn dist(a: Pos, b: Pos) -> Sort {
  #(
    a,
    b,
    result.unwrap(int.power(a.0 - b.0, 2.), 0.)
    +. result.unwrap(int.power(a.1 - b.1, 2.), 0.)
    +. result.unwrap(int.power(a.2 - b.2, 2.), 0.)
  )
}

fn compare_single_list(s: Pos, d: List(Pos)) -> List(Sort) {
  list.map(d, fn(dv) {dist(s, dv)})
}

fn compare_list_with_itself(d: List(Pos)) -> List(Sort) {
  case d {
    [] -> []
    [h, ..t] -> {
      list.append(compare_single_list(h, t), compare_list_with_itself(t))
    }
  }
}

fn map_links(g: Graph, l: List(Sort), ngn: Int, last: Option(Sort)) -> #(Graph, Option(Sort)) {
  let filtered = dict.values(g)
    |> list.filter(option.is_some)
    |> list.fold(dict.new(), fn(acc, a) {
      case dict.get(acc, a) {
        Error(_) -> dict.insert(acc, a, 1)
        Ok(v) -> dict.insert(acc, a, v+1)
      }
    })
  let end_cond = filtered
    |> dict.to_list
    |> list.first
    |> result.map(fn(e) {dict.size(filtered) == 1 && e.1 == dict.size(g)})
    |> result.unwrap(False)

  case end_cond {
    True -> #(g, last)
    False -> case l {
      [] -> #(g, last)
      [h, ..t] -> {
        let a = case dict.get(g, h.0) {
          Ok(v) -> v
          Error(_) -> panic
        }
        let b = case dict.get(g, h.1) {
          Ok(v) -> v
          Error(_) -> panic
        }
        case a {
          None -> case b {
            None -> {
              dict.insert(g, h.0, Some(ngn)) |> dict.insert(h.1, Some(ngn)) |> map_links(t, ngn+1, Some(h))
            }
            Some(bv) -> {
              dict.insert(g, h.0, Some(bv)) |> map_links(t, ngn, Some(h))
            }
          }
          Some(av) -> case b {
            None -> {
              dict.insert(g, h.1, Some(av)) |> map_links(t, ngn, Some(h))
            }
            Some(bv) -> {
              dict.map_values(g, fn(_, ov) {
                case ov {
                  Some(v) -> case v == bv {
                    True -> Some(av)
                    False -> ov
                  }
                  _ -> ov
                }
              }) |> map_links(t, ngn, last)
            }
          }
        }
      }
    }
  }
}

pub fn main() -> Int {
  let assert Ok(input) = simplifile.read("input.txt")

  let positions = string.trim(input) |> string.split("\n") |> list.map(parse_line)
  let sorts = compare_list_with_itself(positions)
  let average_dist = list.fold(sorts, #(0., 0), fn(acc, s) {#(acc.0 +. s.2, acc.1 + 1)})
    |> fn(t) {t.0 /. int.to_float(t.1)}
  let sorted = list.filter(sorts, fn(n) {n.2 <. average_dist}) |> list.sort(fn(a,b) {float.compare(a.2, b.2)})
  let original_graph = list.fold(positions, dict.new(), fn(acc, p) {dict.insert(acc, p, None)})
  let links = map_links(original_graph, sorted, 0, None)

  option.unwrap(links.1, #(#(0,0,0), #(0,0,0), 0.))
  |> fn(n) { n.0.0 * n.1.0 }
}
