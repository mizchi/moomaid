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

///|
/// Gantt task identifiers and statuses are metadata, not timeline values.
test "gantt keeps start and duration with optional identifiers" {
  let rendered = render_to_string(
    "gantt\n  section Tasks\n  WithId :task_id, 2026-01-02, 2d\n  Done :done, done_id, 2026-01-04, 1d\n",
  )
  assert_eq(rendered.contains("WithId | 2026-01-02 | 2d"), true)
  assert_eq(rendered.contains("[done] Done | 2026-01-04 | 1d"), true)
}

///|
/// gitGraph attributes do not become part of the visible commit identifier.
test "git graph extracts quoted commit identifiers" {
  let rendered = render_to_string(
    "gitGraph\n  commit id: \"initial\" type: HIGHLIGHT\n  branch feature\n  checkout feature\n  commit id: \"work\" tag: \"v1\"\n",
  )
  assert_eq(rendered.contains("main ● initial"), true)
  assert_eq(rendered.contains("feature ● work"), true)
  assert_eq(rendered.contains("HIGHLIGHT"), false)
}

///|
/// Decision node syntax creates one diamond node instead of a literal identifier.
test "flowchart decision node uses braces as a shape" {
  let rendered = render_to_string(
    "flowchart LR\n  A[Start] --> B{Ready}\n  B --> C[Done]\n",
  )
  assert_eq(rendered.contains("B{Ready}"), false)
  assert_eq(rendered.contains("Ready"), true)
  assert_eq(rendered.contains("◇"), true)
}

///|
/// Nested subgraphs keep a distinct visible container for each level.
test "nested subgraphs render separate frames" {
  let rendered = render_to_string(
    "flowchart TD\n  subgraph outer[Outer]\n    A --> B\n    subgraph inner[Inner]\n      B --> C\n    end\n  end\n",
  )
  assert_eq(rendered.contains("╭─Inner─╮"), true)
}

///|
/// Parallel sequence branches keep their Mermaid `and` label.
test "sequence parallel branches render and" {
  let rendered = render_to_string(
    "sequenceDiagram\n  par left\n    A->>B: One\n  and right\n    B->>A: Two\n  end\n",
  )
  assert_eq(rendered.contains("[and right]"), true)
}

///|
/// Class members remain visible in the body section of class boxes.
test "class diagram renders members" {
  let rendered = render_to_string(
    "classDiagram\n  class User {\n    +String name\n    +login()\n  }\n  User --> Session\n",
  )
  assert_eq(rendered.contains("+String name"), true)
  assert_eq(rendered.contains("+login()"), true)
}

///|
/// ER cardinality remains visible next to the relationship label.
test "er diagram renders cardinality" {
  let rendered = render_to_string("erDiagram\n  USER ||--o{ ORDER : places\n")
  assert_eq(rendered.contains("||--o{"), true)
}
