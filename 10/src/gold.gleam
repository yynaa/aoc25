import gleam/int
import gleam/result
import gleam/dict.{type Dict}
import gleam/option.{type Option, None, Some}
import gleam/string
import gleam/list
import gleam/order.{type Order}
import simplifile

type Button = List(Int)

type Machine {
  Machine(buttons: List(Button), jolt: List(Int))
}

fn parse_machine(s: String) -> Machine {
  let splat = string.split(s, " ")

  let assert Ok(button_strings) = list.rest(splat) |> result.map(fn(l) {list.take(l, list.length(l) - 1)})
  let assert Ok(jolt_string) = list.last(splat)

  let buttons = button_strings
  |> list.map(fn(bs) {
    bs
    |> string.drop_start(1)
    |> string.drop_end(1)
    |> string.split(",")
    |> list.try_map(int.parse)
    |> result.unwrap([])
  })

  let jolt = jolt_string
  |> string.drop_start(1)
  |> string.drop_end(1)
  |> string.split(",")
  |> list.try_map(int.parse)
  |> result.unwrap([])

  Machine(buttons: buttons, jolt: jolt)
}

fn linearize(m: Machine) -> List(#(Dict(Button, Nil), Int)) {
  list.range(0, list.length(m.jolt) - 1)
  |> list.zip(m.jolt)
  |> list.map(fn(g) {
    #(
      list.fold(m.buttons, dict.new(), fn(d, b) {
        case list.contains(b, g.0) {
          False -> d
          True -> dict.insert(d, b, Nil)
        }
      }),
      g.1
    )
  })
  |> list.sort(fn(a,b) {int.compare(dict.size(a.0), dict.size(b.0))})
}

fn possibilities(length: Int, v: Int) -> List(List(Int)) {
  case length {
    1 -> [[v]]
    n -> {
      list.range(0,v)
      |> list.map(fn(a) {#(a, v-a)})
      |> list.map(fn(a) {list.map(possibilities(n-1, a.1), fn(b) {[a.0, ..b]})})
      |> list.fold([], list.append)
    }
  }
}

fn list_compare(a: List(Int), b: List(Int)) -> Order {
  case a {
    [] -> panic
    [ah, ..at] -> case b {
      [] -> panic
      [bh, ..bt] -> {
        case int.compare(ah, bh) {
          order.Eq -> list_compare(at, bt)
          e -> e
        }
      }
    }
  }
}

fn sorted_possibilities(length: Int, v: Int) -> List(List(Int)) {
  possibilities(length, v)
  |> list.sort(list_compare)
  |> list.reverse
}

fn heuristic_ish_not_really_but_almost(m: Machine, s: Dict(Button, #(Bool, Int))) -> Bool {
  let a = m.jolt
  |> fn(n) {list.zip(list.range(0, list.length(n) - 1), n)}
  |> dict.from_list

  dict.fold(s, dict.map_values(a, fn(_, _) {0}), fn(acc, k, v) {
    list.fold(k, acc, fn(acc2, c) {
      let assert Ok(ov) = dict.get(acc2, c)
      dict.insert(acc2, c, ov + v.1)
    })
  })
  |> dict.to_list
  |> list.sort(fn(a,b) {int.compare(a.0, b.0)})
  |> fn(n) {list.unzip(n).1 |> list.zip(m.jolt)}
  |> list.all(fn(n) {n.0 <= n.1})
}

fn solve_line(m: Machine, p: #(Dict(Button, Nil), Int), s: Dict(Button, #(Bool, Int))) -> List(Dict(Button, #(Bool, Int))) {
  let adapted_problem = dict.fold(s, p, fn(ap, k, v) {
    case v.0 {
      False -> ap
      True -> case v.0 {
        True -> #(dict.delete(ap.0, k), case dict.has_key(p.0, k) {
          True -> ap.1 - v.1
          False -> ap.1
        })
        False -> #(dict.delete(ap.0, k), ap.1)
      }
    }
  })

  // echo "--- adapting problem ---"
  // echo "> problem"
  // echo p
  // echo "> solution"
  // echo s
  // echo "> adapted"
  // echo adapted_problem

  case dict.size(adapted_problem.0) > 0 {
    False -> case adapted_problem.1 {
      0 -> [s]
      _ -> []
    }
    True -> {
      let no_values = s
      |> dict.filter(fn(k, _) {dict.has_key(adapted_problem.0, k)})
      |> dict.size

      // echo "--- solving undefined line ---"
      // echo adapted_problem
      // echo "> input solution"
      // echo s |> dict.filter(fn(k, _) {dict.has_key(adapted_problem.0, k)})

      // bool.guard(bools_with_no_value == 0, [], fn() {list.range(0, bools_with_no_value)})
      // |> list.filter(fn(n) {
      //   n % 2 == bool_to_int(adapted_problem.1)
      // })
      // |> list.map(fn(n) {#(n, dict.size(adapted_problem.0) - n)})
      // |> list.map(fn(n) {bool_permutations(n.0, n.1)})
      // |> list.fold([], list.append)
      // |> list.map(fn(n) {list.zip(dict.keys(adapted_problem.0), n)})
      // |> list.map(fn(n) {
      //   list.fold(n, s, fn(ns, nn) {
      //     dict.insert(ns, nn.0, Some(nn.1))
      //   })
      // })

      let r = sorted_possibilities(no_values, adapted_problem.1)
      // we sort the buttons, maximum damage baby
      |> list.map(fn(n) {list.zip(dict.keys(adapted_problem.0) |> list.sort(fn(a,b) {int.compare(list.length(b), list.length(a))}), n)})
      |> list.map(fn(buttons_to_apply) {
        list.fold(buttons_to_apply, s, fn(acc, button_to_apply) {
          let assert Ok(v) = dict.get(acc, button_to_apply.0)
          dict.insert(acc, button_to_apply.0, #(True, v.1 + button_to_apply.1))
        })
      })
      |> list.filter(fn(new_solution) {
        heuristic_ish_not_really_but_almost(m, new_solution)
      })

      // echo "> output solutions"
      // echo r

      r
    }
  }
}


fn solve_machine(m: Machine, l: List(#(Dict(Button, Nil), Int)), s: Dict(Button, #(Bool, Int))) -> Int {
  case l {
    [] -> dict.fold(s, 0, fn(a, _, v) {
      case v.0 {
        True -> a + v.1
        False -> a
      }
    })
    [lh, ..lt] -> {
      // echo "--- solving line ---"
      // echo "> line to solve"
      // echo lh
      // echo "> input solution"
      // echo s
      let solutions_for_line = solve_line(m, lh, s)
      // echo "> output solution"
      // echo solutions_for_line
      let best_solves_following = list.map(solutions_for_line, solve_machine(m ,lt, _))

      list.fold(best_solves_following, 1000000000, int.min)
    }
  }
}

pub fn main() -> Int {
  let assert Ok(input) = simplifile.read("test_input.txt")
  let machines = string.trim(input) |> string.split("\n") |> list.map(parse_machine)

  let linearized = list.map(machines, linearize)
  let empty_solutions = list.map(machines, fn(m) {
    list.fold(m.buttons, dict.new(), fn(a, b) {
      dict.insert(a, b, #(False, 0))
    })
  })
  let zipped = list.zip(list.zip(machines, linearized), empty_solutions)
  let solve = list.map(zipped, fn(a) {
    echo a.0.0
    solve_machine(a.0.0, a.0.1, a.1)
  })

  list.fold(solve, 0, int.add)
}
