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

fn filter_unused(l: List(a), f: fn(a, a) -> Bool) -> List(a) {
  list.filter(l, fn(e) {
    bool.negate(list.fold(l, False, fn(acc, ee) {
      acc || f(e, ee)
    }))
  })
}

fn candidates(wl: List(List(Pos))) -> Candidates {
  let fp = candidates_first_pass(wl)
  Candidates(
    tl: filter_unused(fp.tl, fn(d, r) {
      r.0 < d.0 && r.1 < d.1
    }),
    tr: filter_unused(fp.tr, fn(d, r) {
      r.0 > d.0 && r.1 < d.1
    }),
    bl: filter_unused(fp.bl, fn(d, r) {
      r.0 < d.0 && r.1 > d.1
    }),
    br: filter_unused(fp.br, fn(d, r) {
      r.0 > d.0 && r.1 > d.1
    })
  )
}

fn max_rect_in_two_corners(c: List(Pos), d: List(Pos)) -> Int {
  list.fold(c, 0, fn(acc_a, a) {
    int.max(acc_a, list.fold(d, 0, fn(acc_b, b) {
      int.max(acc_b, area(a,b))
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

  let max_area_tl_br = max_rect_in_two_corners(cand.tl, cand.br)
  let max_area_bl_tr = max_rect_in_two_corners(cand.bl, cand.tr)

  int.max(max_area_tl_br, max_area_bl_tr)
}
