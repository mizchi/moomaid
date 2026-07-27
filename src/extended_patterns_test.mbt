///|
/// Subgraphs remain visible while their contained flowchart nodes are laid out.
test "render flowchart subgraph" {
  let rendered = render_to_string(
    "flowchart TD\n  subgraph payments[決済]\n    API --> DB\n  end\n  Client --> API\n",
  )
  assert_eq(rendered.contains("決済"), true)
  assert_eq(rendered.contains("Client"), true)
}

///|
/// Extended sequence constructs preserve aliases and render their annotations.
test "render extended sequence diagram" {
  let rendered = render_to_string(
    "sequenceDiagram\n  participant C as Client\n  participant API\n  autonumber\n  C->>+API: Request\n  Note right of API: 処理中\n  alt success\n    API-->>-C: Response\n  else failure\n    API-->>-C: Error\n  end\n",
  )
  assert_eq(rendered.contains("Client"), true)
  assert_eq(rendered.contains("1. Request"), true)
  assert_eq(rendered.contains("処理中"), true)
  assert_eq(rendered.contains("alt success"), true)
}

///|
/// Timeline syntax is parsed as a dedicated diagram rather than a flowchart.
test "parse and render timeline" {
  let parsed = parse(
    "timeline\n  title Releases\n  2025 : v0.1\n  2026 : v0.2\n",
  )
  match parsed {
    Timeline(diagram) => assert_eq(diagram.items.length(), 2)
    _ => assert_eq(true, false)
  }
  let rendered = render_to_string("timeline\n  2025 : v0.1\n  2026 : v0.2\n")
  assert_eq(rendered.contains("2026"), true)
}

///|
/// GitGraph commands are represented as commits on their checked-out branch.
test "parse and render git graph" {
  let parsed = parse(
    "gitGraph\n  commit id: \"initial\"\n  branch feature\n  checkout feature\n  commit id: \"work\"\n  checkout main\n  merge feature\n",
  )
  match parsed {
    GitGraph(diagram) => assert_eq(diagram.events.length(), 6)
    _ => assert_eq(true, false)
  }
  let rendered = render_to_string("gitGraph\n  commit id: \"initial\"\n")
  assert_eq(rendered.contains("initial"), true)
}

///|
/// Gantt tasks keep their section, start and duration in a dedicated model.
test "parse and render gantt" {
  let parsed = parse(
    "gantt\n  title Release\n  dateFormat YYYY-MM-DD\n  section Build\n  Compile :done, build, 2026-01-01, 2d\n",
  )
  match parsed {
    Gantt(diagram) => assert_eq(diagram.tasks.length(), 1)
    _ => assert_eq(true, false)
  }
  let rendered = render_to_string(
    "gantt\n  section Build\n  Compile :done, build, 2026-01-01, 2d\n",
  )
  assert_eq(rendered.contains("Compile"), true)
  assert_eq(rendered.contains("2d"), true)
}

///|
/// Every newly supported diagram type remains available from the SVG API.
test "render extended diagram types as svg" {
  assert_eq(
    experimental_render_to_svg("timeline\n  2026 : v0.2\n").contains("<svg"),
    true,
  )
  assert_eq(
    experimental_render_to_svg("gitGraph\n  commit id: \"initial\"\n").contains(
      "<svg",
    ),
    true,
  )
  assert_eq(
    experimental_render_to_svg("gantt\n  Build :done, id, 2026-01-01, 1d\n").contains(
      "<svg",
    ),
    true,
  )
  assert_eq(
    experimental_render_to_svg(
      "sequenceDiagram\n  autonumber\n  A->>B: Request\n",
    ).contains("<svg"),
    true,
  )
}
