import gleam/int
import gleam/result
import gleam/float
import gleam/time/timestamp
import gleam/time/duration
import gleam/list
import gleam/io
import argv

import silver
import gold


fn bench(f: fn() -> Int, n: Int) -> List(Float) {
  case n {
    0 -> []
    _ -> {
      let start = timestamp.system_time()
      f()
      let time_spent = timestamp.system_time() |> timestamp.difference(start, _) |> duration.to_seconds
      [time_spent, ..bench(f, n-1)]
    }
  }
}

fn benchmark() -> Nil {
  let n = 500
  echo bench(silver.main, n) |> list.fold(0., float.add) |> float.divide(int.to_float(n)) |> result.unwrap(-1.)
  echo bench(gold.main, n) |> list.fold(0., float.add) |> float.divide(int.to_float(n)) |> result.unwrap(-1.)
  Nil
}

pub fn main() -> Nil {
  case argv.load().arguments {
    ["s"] -> {echo silver.main() Nil}
    ["g"] -> {echo gold.main() Nil}
    ["b"] -> benchmark()
    _ -> io.println("usage: gleam run s|g")
  }
  Nil
}
