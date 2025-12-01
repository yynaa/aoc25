import gleam/time/timestamp
import gleam/time/duration
import argv

import silver
import gold

pub fn main() -> Nil {
  let assert Ok(func) = case argv.load().arguments {
    ["s"] -> Ok(silver.main)
    ["g"] -> Ok(gold.main)
    _ -> Error("usage: gleam run s|g")
  }

  let start = timestamp.system_time()
  func()
  echo timestamp.system_time() |> timestamp.difference(start, _) |> duration.to_seconds
  Nil
}
