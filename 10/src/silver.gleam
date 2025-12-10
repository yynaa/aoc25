import gleam/int
import gleam/result
import gleam/dict.{type Dict}
import gleam/option.{type Option, None, Some}
import gleam/string
import gleam/list
import gleam/bool
import simplifile

type Lights = List(Bool)
type Button = List(Int)

type Machine {
  Machine(goal: Lights, buttons: List(Button))
}

fn parse_machine(s: String) -> Machine {
  let splat = string.split(s, " ")

  let assert Ok(goal_string) = list.first(splat)
  let assert Ok(button_strings) = list.rest(splat) |> result.map(fn(l) {list.take(l, list.length(l) - 1)})

  let goal = goal_string
  |> string.drop_start(1)
  |> string.drop_end(1)
  |> string.to_graphemes
  |> list.map(fn(g) {case g {
    "#" -> True
    _ -> False
  }})
  // |> fn(g) {list.zip(g, list.range(0, list.length(g) - 1))}
  // |> list.fold(dict.new(), fn(acc, gz) {
  //   case gz.0 {
  //     "#" -> dict.insert(acc, gz.1, Nil)
  //     _ -> acc
  //   }
  // })

  let buttons = button_strings
  |> list.map(fn(bs) {
    bs
    |> string.drop_start(1)
    |> string.drop_end(1)
    |> string.split(",")
    |> list.try_map(int.parse)
    |> result.unwrap([])
  })

  Machine(goal: goal, buttons: buttons)
}

fn linearize(m: Machine) -> List(#(Dict(Button, Nil), Bool)) {
  list.range(0, list.length(m.goal) - 1)
  |> list.zip(m.goal)
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

fn bool_permutations(true_left: Int, false_left: Int) -> List(List(Bool)) {
  case true_left > 0 {
    False -> case false_left > 0 {
      False -> []
      True -> [list.repeat(False, false_left)]
    }
    True -> case false_left > 0 {
      False -> [list.repeat(True, true_left)]
      True -> {
        list.append(
          bool_permutations(true_left - 1, false_left) |> list.map(fn(l) {[True, ..l]}),
          bool_permutations(true_left, false_left - 1) |> list.map(fn(l) {[False, ..l]})
        )
      }
    }
  }
}

fn bool_to_int(b: Bool) -> Int {
  case b {
    True -> 1
    False -> 0
  }
}

fn solve_line(p: #(Dict(Button, Nil), Bool), s: Dict(Button, Option(Bool))) -> List(Dict(Button, Option(Bool))) {
  let adapted_problem = dict.fold(s, p, fn(ap, k, v) {
    case v {
      None -> ap
      Some(vv) -> case vv {
        True -> #(dict.delete(ap.0, k), case dict.has_key(p.0, k) {
          True -> bool.negate(ap.1)
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
      False -> [s]
      True -> []
    }
    True -> {
      let bools_with_no_value = s
      |> dict.filter(fn(k, _) {dict.has_key(adapted_problem.0, k)})
      |> dict.size

      // echo "--- solving undefined line ---"
      // echo adapted_problem
      // echo "> input solution"
      // echo s |> dict.filter(fn(k, v) {dict.has_key(adapted_problem.0, k)})
      // echo "> permutations"
      // echo bool.guard(bools_with_no_value == 0, [], fn() {list.range(0, bools_with_no_value)})
      // |> list.filter(fn(n) {
      //   n % 2 == bool_to_int(adapted_problem.1)
      // })

      bool.guard(bools_with_no_value == 0, [], fn() {list.range(0, bools_with_no_value)})
      |> list.filter(fn(n) {
        n % 2 == bool_to_int(adapted_problem.1)
      })
      |> list.map(fn(n) {#(n, dict.size(adapted_problem.0) - n)})
      |> list.map(fn(n) {bool_permutations(n.0, n.1)})
      |> list.fold([], list.append)
      |> list.map(fn(n) {list.zip(dict.keys(adapted_problem.0), n)})
      |> list.map(fn(n) {
        list.fold(n, s, fn(ns, nn) {
          dict.insert(ns, nn.0, Some(nn.1))
        })
      })
    }
  }
}


fn solve_machine(l: List(#(Dict(Button, Nil), Bool)), s: Dict(Button, Option(Bool))) -> Int {
  case l {
    [] -> dict.fold(s, 0, fn(a, _, v) {
      case option.unwrap(v, False) {
        True -> a + 1
        False -> a
      }
    })
    [lh, ..lt] -> {
      // echo "--- solving line ---"
      // echo "> line to solve"
      // echo lh
      // echo "> input solution"
      // echo s
      let solutions_for_line = solve_line(lh, s)
      // echo "> output solution"
      // echo solutions_for_line
      let best_solves_following = list.map(solutions_for_line, solve_machine(lt, _))

      list.fold(best_solves_following, dict.size(s), int.min)
    }
  }
}

pub fn main() -> Int {
  let assert Ok(input) = simplifile.read("input.txt")
  let machines = string.trim(input) |> string.split("\n") |> list.map(parse_machine)

  let linearized = list.map(machines, linearize)
  let empty_solutions = list.map(machines, fn(m) {
    list.fold(m.buttons, dict.new(), fn(a, b) {
      dict.insert(a, b, None)
    })
  })
  let zipped = list.zip(linearized, empty_solutions)
  let solve = list.map(zipped, fn(a) {solve_machine(a.0, a.1)})

  list.fold(solve, 0, int.add)
}
