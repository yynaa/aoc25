import argv
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/time/duration
import gleam/time/timestamp

import gold
import silver

fn bench(f: fn() -> Int, n: Int) -> List(Float) {
  case n {
    0 -> []
    _ -> {
      let start = timestamp.system_time()
      f()
      let time_spent =
        timestamp.system_time()
        |> timestamp.difference(start, _)
        |> duration.to_seconds
      [time_spent, ..bench(f, n - 1)]
    }
  }
}

fn benchmark() -> Nil {
  let n = 50
  echo bench(silver.main, n)
    |> list.fold(0.0, float.add)
    |> float.divide(int.to_float(n))
    |> result.unwrap(-1.0)
  echo bench(gold.main, n)
    |> list.fold(0.0, float.add)
    |> float.divide(int.to_float(n))
    |> result.unwrap(-1.0)
  Nil
}

pub fn main() -> Nil {
  case argv.load().arguments {
    ["s"] -> {
      echo silver.main()
      Nil
    }
    ["g"] -> {
      echo gold.main()
      Nil
    }
    ["b"] -> benchmark()
    _ -> io.println("usage: gleam run s|g")
  }
  Nil
}
