import gleam/int
import gleam/list
import gleam/string
import simplifile

type Direction {
  Left
  Right
}

type Instruction = #(Direction, Int)

fn parse_instruction(s: String) -> Instruction {
  let assert Ok(direction_string) = string.first(s)
  let assert Ok(direction) = case direction_string {
    "L" -> Ok(Left)
    "R" -> Ok(Right)
    _ -> Error("Invalid direction letter")
  }
  let assert Ok(int) = string.drop_start(s, 1) |> int.parse
  #(direction, int)
}

fn apply_instruction(n: Int, i: Instruction) -> Int {
  case i.0 {
    Left -> n - i.1
    Right -> n + i.1
  } % 100
}

fn password_folder(state: #(Int, Int), next: Instruction) -> #(Int, Int) {
  let new_number = apply_instruction(state.0, next)
  let password = case new_number {
    0 -> state.1 + 1
    _ -> state.1
  }
  #(new_number, password)
}

pub fn main() -> Int {
  let assert Ok(input) = simplifile.read("input.txt")
  let instructions = string.trim(input) |> string.split("\n") |> list.map(parse_instruction)
  list.fold(instructions, #(50, 0), password_folder).1
}
