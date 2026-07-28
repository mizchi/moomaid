///|
test "debug layout colors graph layers without changing normal SVG" {
  let source = "flowchart LR\n  A -->|注文を作成する| B"
  let normal = experimental_render_to_svg(source)
  let debug = experimental_render_to_svg(
    source,
    options=default_svg_options().with_debug_layout(),
  )
  assert_true(!normal.contains("<g class=\"debug-layout\""))
  assert_true(debug.contains("<g class=\"debug-layout\""))
  assert_true(debug.contains("debug-node-box"))
  assert_true(debug.contains("debug-edge-label-box"))
  assert_true(debug.contains("debug-edge-path"))
}

///|
test "debug layout highlights an edge crossing a subgraph heading" {
  let svg = experimental_render_to_svg(
    "flowchart TD\n  subgraph first[最初のグループ]\n    A\n  end\n  subgraph second[次のグループ]\n    B\n  end\n  A --> B",
    options=default_svg_options().with_debug_layout(),
  )
  assert_true(svg.contains("debug-subgraph-label-box"))
  assert_true(svg.contains("debug-collision"))
}

///|
test "debug geometry detects crossing line segments at different positions" {
  let first_start : DebugPoint = { px: 0.0, py: 0.0 }
  let first_end : DebugPoint = { px: 100.0, py: 100.0 }
  let second_start : DebugPoint = { px: 0.0, py: 100.0 }
  let second_end : DebugPoint = { px: 100.0, py: 0.0 }
  assert_true(
    debug_segments_intersect(first_start, first_end, second_start, second_end),
  )
}
