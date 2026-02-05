///|
test "parse flowchart" {
  let text =
    #|graph TD
    #|  A[Start] --> B[End]
    #|
  let diagram = parse(text)
  inspect(
    diagram,
    content=(
      #|Graph({kind: Flowchart, direction: TD, nodes: [{id: "A", label: "Start", shape: Rect, sections: [["Start"]]}, {id: "B", label: "End", shape: Rect, sections: [["End"]]}], edges: [{from: "A", to: "B", label: None}]})
    ),
  )
}

///|
test "render flowchart ascii snapshot" {
  let text =
    #|graph TD
    #|  A --> B
    #|
  let ascii = render_to_string(text)
  inspect(
    ascii,
    content=(
      #|┌───┐
      #|│ A │
      #|└───┘
      #|  │
      #|  │
      #|┌───┐
      #|│ B │
      #|└───┘
    ),
  )
}

///|
test "render flowchart LR ascii snapshot" {
  let text =
    #|graph LR
    #|  A --> B
    #|
  let ascii = render_to_string(text)
  inspect(
    ascii,
    content=(
      #|┌───┐  ┌───┐
      #|│ A │──│ B │
      #|└───┘  └───┘
    ),
  )
}

///|
test "render state ascii snapshot" {
  let text =
    #|stateDiagram-v2
    #|  [*] --> Idle
    #|  Idle --> [*]
    #|
  let ascii = render_to_string(text)
  inspect(
    ascii,
    content=(
      #|
      #|   ●
      #|
      #|   └┐
      #|    │
      #|╭──────╮
      #|│ Idle │
      #|╰──────╯
      #|   ┌┘
      #|   │
      #|   ▼
      #|   ◎
    ),
  )
}

///|
test "render sequence ascii snapshot" {
  let text =
    #|sequenceDiagram
    #|  participant Alice
    #|  participant Bob
    #|  Alice->>Bob: Hello
    #|
  let ascii = render_to_string(text)
  inspect(
    ascii,
    content=(
      #|  ┌─────────┐      ┌───────┐
      #|  │ Alice   │      │ Bob   │
      #|  └─────────┘      └───────┘
      #|       │Hello          │
      #|       ────────────────▶
      #|       │               │
    ),
  )
}

///|
test "render class ascii snapshot" {
  let text =
    #|classDiagram
    #|  class Animal
    #|  Animal : +int age
    #|  Animal : +eat()
    #|
  let ascii = render_to_string(text)
  inspect(
    ascii,
    content=(
      #|┌──────────┐
      #|│ Animal   │
      #|│──────────│
      #|│ +int age │
      #|│ +eat()   │
      #|└──────────┘
    ),
  )
}

///|
test "render er ascii snapshot" {
  let text =
    #|erDiagram
    #|  CUSTOMER ||--o{ ORDER : places
    #|
  let ascii = render_to_string(text)
  inspect(
    ascii,
    content=(
      #|┌──────────┐
      #|│ CUSTOMER │
      #|└──────────┘
      #|     places
      #|     │
      #| ┌───────┐
      #| │ ORDER │
      #| └───────┘
    ),
  )
}

///|
test "render svg has correct structure" {
  let text =
    #|graph TD
    #|  A --> B
    #|
  let svg = experimental_render_to_svg(text)
  assert_true(svg.contains("<svg"))
  assert_true(svg.contains("<g class=\"edges\">"))
  assert_true(svg.contains("<g class=\"nodes\">"))
  assert_true(svg.contains("</svg>"))
}

///|
test "svg_options_from_theme returns options for known theme" {
  let opts = svg_options_from_theme("github-dark")
  assert_true(opts is Some(_))
}

///|
test "svg_options_from_theme returns None for unknown theme" {
  let opts = svg_options_from_theme("nonexistent")
  assert_true(opts is None)
}

///|
test "render sequence svg structure" {
  let text =
    #|sequenceDiagram
    #|  Alice->>Bob: Hi
    #|  Bob-->>Alice: Hey
    #|
  let svg = experimental_render_to_svg(text)
  assert_true(svg.contains("<g class=\"lifelines\">"))
  assert_true(svg.contains("<g class=\"actors\">"))
  assert_true(svg.contains("<g class=\"messages\">"))
  assert_true(svg.contains("stroke-dasharray"))
}

///|
test "render_to_string returns non-empty" {
  let text =
    #|graph TD
    #|  A --> B
    #|
  let ascii = render_to_string(text)
  assert_true(ascii.length() > 0)
}

///|
test "render flowchart with edge label" {
  let text =
    #|graph TD
    #|  A -->|yes| B
    #|  A -->|no| C
    #|
  let ascii = render_to_string(text)
  inspect(
    ascii,
    content=(
      #|    ┌───┐
      #|    │ A │
      #|    └───┘
      #|  ┌─yes─no─┐
      #|  │        │
      #|┌───┐    ┌───┐
      #|│ B │    │ C │
      #|└───┘    └───┘
    ),
  )
}

///|
test "parse chained edges" {
  let text =
    #|graph LR
    #|  Input --> Process --> Output
    #|
  let diagram = parse(text)
  inspect(
    diagram,
    content=(
      #|Graph({kind: Flowchart, direction: LR, nodes: [{id: "Input", label: "Input", shape: Rect, sections: [["Input"]]}, {id: "Process", label: "Process", shape: Rect, sections: [["Process"]]}, {id: "Output", label: "Output", shape: Rect, sections: [["Output"]]}], edges: [{from: "Input", to: "Process", label: None}, {from: "Process", to: "Output", label: None}]})
    ),
  )
}

///|
test "render flow td full diagram" {
  let text =
    #|graph TD
    #|  A[Start] --> B(Decision)
    #|  B -->|yes| C[Success]
    #|  B -->|no| D[Retry]
    #|  D --> B
    #|
  let ascii = render_to_string(text)
  inspect(
    ascii,
    content=(
      #|     ┌───────┐
      #|     │ Start │
      #|     └───────┘
      #|         │
      #|         │
      #|       ╭───╮
      #|       │ B │
      #|       ╰───╯
      #|     ┌─yes───no──┐
      #|     │   │       │
      #|┌─────────┐    ┌───┐
      #|│ Success││    │ D │
      #|└─────────┘    └───┘
      #|         └───────┘
    ),
  )
}

///|
test "render flowchart with max_width" {
  let text =
    #|graph TD
    #|  A --> B
    #|  A --> C
    #|
  let options : @moomaid.Options = {
    use_ascii: false,
    padding_x: 2,
    padding_y: 1,
    box_border_padding: 1,
    max_width: 40,
  }
  let ascii = @moomaid.render_to_string(text, options~)
  inspect(
    ascii,
    content=(
      #|    ┌───┐
      #|    │ A │
      #|    └───┘
      #|  ┌───┴────┐
      #|  │        │
      #|┌───┐    ┌───┐
      #|│ B │    │ C │
      #|└───┘    └───┘
    ),
  )
}

///|
test "render sequence with max_width" {
  let text =
    #|sequenceDiagram
    #|  participant Alice
    #|  participant Bob
    #|  Alice->>Bob: Hello
    #|
  let options : @moomaid.Options = {
    use_ascii: false,
    padding_x: 2,
    padding_y: 1,
    box_border_padding: 1,
    max_width: 60,
  }
  let ascii = @moomaid.render_to_string(text, options~)
  inspect(
    ascii,
    content=(
      #|  ┌─────────┐      ┌───────┐
      #|  │ Alice   │      │ Bob   │
      #|  └─────────┘      └───────┘
      #|       │Hello          │
      #|       ────────────────▶
      #|       │               │
    ),
  )
}

///|
test "render svg bezier edges" {
  let text =
    #|graph TD
    #|  A --> B
    #|  A --> C
    #|
  let svg = experimental_render_to_svg(text)
  assert_true(svg.contains("<path d=\"M"))
}
