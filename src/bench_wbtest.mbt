///|
extern "js" fn perf_now() -> Double =
  #| () => performance.now()

///|
let bench_flow_small : String =
  #|graph TD
  #|  A --> B
  #|

///|
let bench_flow_medium : String =
  #|graph TD
  #|  A[Start] --> B(Decision)
  #|  B -->|yes| C[Success]
  #|  B -->|no| D[Retry]
  #|  D --> B
  #|

///|
let bench_flow_large : String =
  #|graph LR
  #|  A[Input] --> B[Parse]
  #|  B --> C[Validate]
  #|  C --> D[Transform]
  #|  D --> E[Layout]
  #|  E --> F[Render]
  #|  F --> G[Output]
  #|  C -->|error| H[Report]
  #|  H --> A
  #|  D -->|cache| I[Cache]
  #|  I --> F
  #|

///|
let bench_sequence : String =
  #|sequenceDiagram
  #|  participant Client
  #|  participant Server
  #|  participant DB
  #|  Client->>Server: Request
  #|  Server->>DB: Query
  #|  DB-->>Server: Result
  #|  Server-->>Client: Response
  #|

///|
let bench_state : String =
  #|stateDiagram-v2
  #|  [*] --> Idle
  #|  Idle --> Running
  #|  Running --> Idle
  #|  Running --> [*]
  #|

///|
fn fmt_num(s : String, max_len : Int) -> String {
  if s.length() <= max_len {
    return s
  }
  let sb = StringBuilder::new()
  let mut i = 0
  for c in s {
    if i >= max_len {
      break
    }
    sb.write_char(c)
    i += 1
  }
  sb.to_string()
}

///|
fn bench(name : String, n : Int, f : () -> Unit) -> Unit {
  // warmup
  for _ in 0..<(n / 10) {
    f()
  }
  let start = perf_now()
  for _ in 0..<n {
    f()
  }
  let elapsed = perf_now() - start
  let per_iter = elapsed / n.to_double()
  let ops_per_sec = 1000.0 / per_iter
  let pi = fmt_num(per_iter.to_string(), 6)
  let os = fmt_num(ops_per_sec.to_string(), 7)
  let el = fmt_num(elapsed.to_string(), 6)
  println("  \{name}: \{pi}ms/iter (\{os} ops/s, \{n} iters in \{el}ms)")
}

///|
test "bench: parse" {
  let n = 2000
  println("=== Parse Benchmarks ===")
  bench("flow_small", n, fn() { let _ = parse_mermaid(bench_flow_small) })
  bench("flow_medium", n, fn() { let _ = parse_mermaid(bench_flow_medium) })
  bench("flow_large", n, fn() { let _ = parse_mermaid(bench_flow_large) })
  bench("sequence", n, fn() { let _ = parse_mermaid(bench_sequence) })
  bench("state", n, fn() { let _ = parse_mermaid(bench_state) })
}

///|
test "bench: layout" {
  let n = 2000
  let opts = default_ascii_options()
  println("=== Layout Benchmarks ===")
  let flow_sm = match parse_mermaid(bench_flow_small) {
    Graph(g) => g
    _ => panic()
  }
  bench("flow_small", n, fn() { let _ = layout_graph(flow_sm, opts) })
  let flow_md = match parse_mermaid(bench_flow_medium) {
    Graph(g) => g
    _ => panic()
  }
  bench("flow_medium", n, fn() { let _ = layout_graph(flow_md, opts) })
  let flow_lg = match parse_mermaid(bench_flow_large) {
    Graph(g) => g
    _ => panic()
  }
  bench("flow_large", n, fn() { let _ = layout_graph(flow_lg, opts) })
  let seq = match parse_mermaid(bench_sequence) {
    Sequence(s) => s
    _ => panic()
  }
  bench("sequence", n, fn() { let _ = layout_sequence(seq, opts) })
}

///|
test "bench: render ascii" {
  let n = 2000
  let opts = default_ascii_options()
  println("=== Render ASCII Benchmarks ===")
  let flow_sm = match parse_mermaid(bench_flow_small) {
    Graph(g) => g
    _ => panic()
  }
  bench("flow_small", n, fn() { let _ = render_graph_ascii(flow_sm, opts) })
  let flow_md = match parse_mermaid(bench_flow_medium) {
    Graph(g) => g
    _ => panic()
  }
  bench("flow_medium", n, fn() { let _ = render_graph_ascii(flow_md, opts) })
  let flow_lg = match parse_mermaid(bench_flow_large) {
    Graph(g) => g
    _ => panic()
  }
  bench("flow_large", n, fn() { let _ = render_graph_ascii(flow_lg, opts) })
  let seq = match parse_mermaid(bench_sequence) {
    Sequence(s) => s
    _ => panic()
  }
  bench("sequence", n, fn() { let _ = render_sequence_ascii(seq, opts) })
}

///|
test "bench: render svg" {
  let n = 2000
  let svg_opts = default_render_options()
  println("=== Render SVG Benchmarks ===")
  let flow_sm = match parse_mermaid(bench_flow_small) {
    Graph(g) => g
    _ => panic()
  }
  bench("flow_small", n, fn() { let _ = render_graph_svg(flow_sm, svg_opts) })
  let flow_md = match parse_mermaid(bench_flow_medium) {
    Graph(g) => g
    _ => panic()
  }
  bench("flow_medium", n, fn() { let _ = render_graph_svg(flow_md, svg_opts) })
  let flow_lg = match parse_mermaid(bench_flow_large) {
    Graph(g) => g
    _ => panic()
  }
  bench("flow_large", n, fn() { let _ = render_graph_svg(flow_lg, svg_opts) })
  let seq = match parse_mermaid(bench_sequence) {
    Sequence(s) => s
    _ => panic()
  }
  bench("sequence", n, fn() { let _ = render_sequence_svg(seq, svg_opts) })
}

///|
test "bench: full pipeline" {
  let n = 2000
  println("=== Full Pipeline (parse + layout + render) ===")
  bench("ascii_small", n, fn() { let _ = render_to_string(bench_flow_small) })
  bench("ascii_medium", n, fn() { let _ = render_to_string(bench_flow_medium) })
  bench("ascii_large", n, fn() { let _ = render_to_string(bench_flow_large) })
  bench("svg_small", n, fn() {
    let _ = experimental_render_to_svg(bench_flow_small)
  })
  bench("svg_medium", n, fn() {
    let _ = experimental_render_to_svg(bench_flow_medium)
  })
  bench("svg_large", n, fn() {
    let _ = experimental_render_to_svg(bench_flow_large)
  })
}

///|
test "bench: canvas operations" {
  let n = 5000
  println("=== Canvas Operations ===")
  bench("new(80x20)", n, fn() { let _ = Canvas::new(80, 20) })
  bench("new(200x50)", n, fn() { let _ = Canvas::new(200, 50) })
  let canvas = Canvas::new(80, 20)
  bench("render(80x20)", n, fn() { let _ = canvas.render() })
  let big_canvas = Canvas::new(200, 50)
  bench("render(200x50)", n, fn() { let _ = big_canvas.render() })
}
