import gleam/bool
import gleam/result
import gleam/int
import gleam/string
import gleam/list
import simplifile

type Pos = #(Int, Int)
type Candidates {
  Candidates(tl: List(Pos), tr: List(Pos), bl: List(Pos), br: List(Pos))
}

fn area(a: Pos, b: Pos) -> Int {
  int.multiply(int.absolute_value(a.0 - b.0) + 1, int.absolute_value(a.1 - b.1) + 1)
}

fn set_correct_order_for_rect(a: Pos, b: Pos) -> #(Pos, Pos) {
  case a.0 > b.0 {
    False -> #(a, b)
    True -> #(b, a)
  }
}

fn line_collides_rect(p: Pos, q: Pos, c: Pos, d: Pos) -> Bool {
  let mx = int.min(p.0, q.0)
  let my = int.min(p.1, q.1)
  let nx = int.max(p.0, q.0)
  let ny = int.max(p.1, q.1)
  let #(a, b) = set_correct_order_for_rect(c, d)
  let ax = a.0
  let ay = a.1
  let bx = b.0
  let by = b.1
  let r = case mx == nx {
    True -> {
      // vertical line
      case ay < by {
        True -> {
          // tl-br

          mx > ax && mx < bx && ny > ay && my < by
        }
        False -> {
          // bl-tr
          mx > ax && mx < bx && ny > by && my < ay
        }
      }
    }
    False -> {
      // hor line
      case ay < by {
        True -> {
          // tl-br
          my > ay && my < by && nx > ax && mx < bx
        }
        False -> {
          // #(1906,50085), #(94967,50085), #(95007, 66765), #(18528, 13199)
          // bl-tr
          my > by && my < ay && nx > ax && mx < bx
        }
      }
    }
  }
  r
}

fn parse_pos(s: String) -> Pos {
  string.split(s, ",")
    |> list.try_map(int.parse)
    |> result.unwrap([])
    |> list.window_by_2
    |> list.first
    |> result.unwrap(#(0,0))
}

fn candidates_first_pass(wl: List(List(Pos))) -> Candidates {
  case wl {
    [] -> Candidates([], [], [], [])
    [[p,c,n], ..tail] -> {
      let rec = candidates_first_pass(tail)
      let px = p.0
      let py = p.1
      let cx = c.0
      let cy = c.1
      let nx = n.0
      let ny = n.1

      rec
      |> fn(cs) {
        let ba = py > cy && nx > cx
        let bb = ny > cy && px > cx
        bool.guard(bool.negate(ba || bb), cs, fn() {
          Candidates(..cs, tl:[c, ..cs.tl])
        })
      }
      |> fn(cs) {
        let ba = py > cy && nx < cx
        let bb = ny > cy && px < cx
        bool.guard(bool.negate(ba || bb), cs, fn() {
          Candidates(..cs, tr:[c, ..cs.tr])
        })
      }
      |> fn(cs) {
        let ba = py < cy && nx > cx
        let bb = ny < cy && px > cx
        bool.guard(bool.negate(ba || bb), cs, fn() {
          Candidates(..cs, bl:[c, ..cs.bl])
        })
      }
      |> fn(cs) {
        let ba = py < cy && nx < cx
        let bb = ny < cy && px < cx
        bool.guard(bool.negate(ba || bb), cs, fn() {
          Candidates(..cs, br:[c, ..cs.br])
        })
      }
    }
    _ -> panic
  }
}

fn filter_unused(l: List(a), f: fn(a, a) -> Bool) -> #(List(a), List(a)) {
  list.fold(l, #([], []), fn(acc, e) {
    case list.fold(l, False, fn(acc, ee) {
      acc || f(e, ee)
    }) {
      True -> #(acc.0, [e, ..acc.1])
      False -> #([e, ..acc.0], acc.1)
    }
  })
}

fn candidates(wl: List(List(Pos))) -> Candidates {
  let fp = candidates_first_pass(wl)
  let #(tl_cand, tl_left) = filter_unused(fp.tl, fn(d, r) {
    r.0 < d.0 && r.1 < d.1
  })
  let #(tr_cand, tr_left) = filter_unused(fp.tr, fn(d, r) {
    r.0 > d.0 && r.1 < d.1
  })
  let #(bl_cand, bl_left) = filter_unused(fp.bl, fn(d, r) {
    r.0 < d.0 && r.1 > d.1
  })
  let #(br_cand, br_left) = filter_unused(fp.br, fn(d, r) {
    r.0 > d.0 && r.1 > d.1
  })

  Candidates(
    tl: tl_cand |> list.append(tr_left) |> list.append(bl_left),
    tr: tr_cand |> list.append(tl_left) |> list.append(br_left),
    bl: bl_cand |> list.append(tl_left) |> list.append(br_left),
    br: br_cand |> list.append(tr_left) |> list.append(bl_left)
  )
}

fn max_rect_in_two_corners(all: List(#(Pos, Pos)), c: List(Pos), d: List(Pos)) -> Int {
  list.fold(c, 0, fn(acc_a, a) {
    int.max(acc_a, list.fold(d, 0, fn(acc_b, b) {
      case list.fold(all, False, fn(acc_c, all_e) {
        acc_c || line_collides_rect(all_e.0, all_e.1, a, b)
      }) {
        True -> acc_b
        False -> int.max(acc_b, area(a,b))
      }
    }))
  })
}

pub fn main() -> Int {
  let assert Ok(input) = simplifile.read("input.txt")
  let pos = string.trim(input) |> string.split("\n") |> list.map(parse_pos)
  let cand = [
    list.last(pos) |> result.unwrap(#(0,0)),
    ..list.append(pos, [list.first(pos) |> result.unwrap(#(0,0))])
  ]
  |> list.window(3)
  |> candidates

  let pos_win = list.window_by_2([list.last(pos) |> result.unwrap(#(0,0)), ..pos])

  let max_area_tl_br = max_rect_in_two_corners(pos_win, cand.tl, cand.br)
  let max_area_bl_tr = max_rect_in_two_corners(pos_win, cand.bl, cand.tr)

  int.max(max_area_tl_br, max_area_bl_tr)
}
