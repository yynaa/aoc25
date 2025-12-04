import gleam/bool
import gleam/int
import gleam/result
import gleam/list
import simplifile
import gleam/string
import gleamy/red_black_tree_map.{type Map} as map
import gleam/order

// --- DATA ---

type Roll {
  Roll(cl: Bool, tc: Bool, cr: Bool, bc: Bool, tl: Bool, tr: Bool, bl: Bool, br: Bool)
}

fn roll_new() -> Roll {
  Roll(False, False, False, False, False, False, False, False)
}

fn roll_4_adj(r: Roll) -> Bool {
  bool_to_int(r.cl)
    |> int.add(bool_to_int(r.tc))
    |> int.add(bool_to_int(r.cr))
    |> int.add(bool_to_int(r.bc))
    |> int.add(bool_to_int(r.tl))
    |> int.add(bool_to_int(r.tr))
    |> int.add(bool_to_int(r.bl))
    |> int.add(bool_to_int(r.br))
  < 4
}

type Position = #(Int, Int)
type Graph = Map(Position, Roll)

// --- HELPERS ---

fn bool_to_int(b: Bool) -> Int {
  case b {
    False -> 0
    True -> 1
  }
}

fn compare_positions(a: Position, b: Position) -> order.Order {
  let yc = int.compare(a.1, b.1)
  case yc {
    order.Eq -> int.compare(a.0, b.0)
    _ -> yc
  }
}

// --- PARSER ---

fn one_liner_to_graph(width: Int, graphemes: List(String), current: Int) -> Graph {
  case graphemes {
    [] -> map.new(compare_positions)
    [head, ..tail] -> case head {
      "@" -> {
        let next = one_liner_to_graph(width, tail, current + 1)

        let x = current % width
        let y = current / width

        let cr = map.find(next, #(x+1, y))
        let bl = map.find(next, #(x-1, y+1))
        let bc = map.find(next, #(x, y+1))
        let br = map.find(next, #(x+1, y+1))

        let cr_not_exists = result.is_error(cr)
        let bl_not_exists = result.is_error(bl)
        let bc_not_exists = result.is_error(bc)
        let br_not_exists = result.is_error(br)

        let roll = roll_new()
          |> fn(r) {bool.guard(cr_not_exists, r, fn() {Roll(..r, cr: True)})}
          |> fn(r) {bool.guard(bl_not_exists, r, fn() {Roll(..r, bl: True)})}
          |> fn(r) {bool.guard(bc_not_exists, r, fn() {Roll(..r, bc: True)})}
          |> fn(r) {bool.guard(br_not_exists, r, fn() {Roll(..r, br: True)})}

        let next = next
          |> fn (n) {
            bool.guard(cr_not_exists, n, fn() {
              let old = result.lazy_unwrap(cr, roll_new)
              map.insert(n, #(x+1, y), Roll(..old, cl: True))
            })
          }
          |> fn (n) {
            bool.guard(bl_not_exists, n, fn() {
              let old = result.lazy_unwrap(bl, roll_new)
              map.insert(n, #(x-1, y+1), Roll(..old, tr: True))
            })
          }
          |> fn (n) {
            bool.guard(bc_not_exists, n, fn() {
              let old = result.lazy_unwrap(bc, roll_new)
              map.insert(n, #(x, y+1), Roll(..old, tc: True))
            })
          }
          |> fn (n) {
            bool.guard(br_not_exists, n, fn() {
              let old = result.lazy_unwrap(br, roll_new)
              map.insert(n, #(x+1, y+1), Roll(..old, tl: True))
            })
          }

        map.insert(next, #(x, y), roll)
      }
      _ -> one_liner_to_graph(width, tail, current + 1)
    }
  }
}

// --- GOLD ---

fn remove_roll_from_graph(g: Graph, p: Position) -> Graph {
  g
    |> map.delete(p)
    |> fn(gm) {
      // cl
      let np = #(p.0 - 1, p.1)
      let nrr = map.find(gm, np)
      result.map(nrr, fn(nr) {map.insert(gm, np, Roll(..nr, cr: False))}) |> result.unwrap(gm)
    }
    |> fn(gm) {
      // cr
      let np = #(p.0 + 1, p.1)
      let nrr = map.find(gm, np)
      result.map(nrr, fn(nr) {map.insert(gm, np, Roll(..nr, cl: False))}) |> result.unwrap(gm)
    }
    |> fn(gm) {
      // tc
      let np = #(p.0, p.1 - 1)
      let nrr = map.find(gm, np)
      result.map(nrr, fn(nr) {map.insert(gm, np, Roll(..nr, bc: False))}) |> result.unwrap(gm)
    }
    |> fn(gm) {
      // bc
      let np = #(p.0, p.1 + 1)
      let nrr = map.find(gm, np)
      result.map(nrr, fn(nr) {map.insert(gm, np, Roll(..nr, tc: False))}) |> result.unwrap(gm)
    }
    |> fn(gm) {
      // tl
      let np = #(p.0 - 1, p.1 - 1)
      let nrr = map.find(gm, np)
      result.map(nrr, fn(nr) {map.insert(gm, np, Roll(..nr, br: False))}) |> result.unwrap(gm)
    }
    |> fn(gm) {
      // tr
      let np = #(p.0 + 1, p.1 - 1)
      let nrr = map.find(gm, np)
      result.map(nrr, fn(nr) {map.insert(gm, np, Roll(..nr, bl: False))}) |> result.unwrap(gm)
    }
    |> fn(gm) {
      // bl
      let np = #(p.0 - 1, p.1 + 1)
      let nrr = map.find(gm, np)
      result.map(nrr, fn(nr) {map.insert(gm, np, Roll(..nr, tr: False))}) |> result.unwrap(gm)
    }
    |> fn(gm) {
      // br
      let np = #(p.0 + 1, p.1 + 1)
      let nrr = map.find(gm, np)
      result.map(nrr, fn(nr) {map.insert(gm, np, Roll(..nr, tl: False))}) |> result.unwrap(gm)
    }
}

fn accessibles(g: Graph) -> List(Position) {
  map.fold(g, [], fn(acc, p, r) {
    case roll_4_adj(r) {
      True -> [p, ..acc]
      False -> acc
    }
  })
}

fn iterate(g: Graph) -> #(Graph, Int) {
  let accessibles = accessibles(g)
  case list.length(accessibles) {
    0 -> #(g, 0)
    na -> {
      let filtered_graph = list.fold(accessibles, g, remove_roll_from_graph)
      let next = iterate(filtered_graph)

      #(next.0, na + next.1)
    }
  }
}

// --- MAIN ---

pub fn main() -> Int {
  let assert Ok(input) = simplifile.read("input.txt")
  let lines = string.trim(input) |> string.split("\n")
  let h = list.length(lines)
  let w = string.length(list.first(lines) |> result.unwrap(""))
  let s = string.concat(lines) |> string.to_graphemes

  let graph = one_liner_to_graph(w, s, 0)

  iterate(graph).1
}
