///|
test "orders a level by its predecessor positions to reduce crossed edges" {
  let diagram = match parse("flowchart LR\n  A --> D\n  B --> C") {
    Graph(graph) => graph
    _ => abort("expected a graph diagram")
  }
  let levels : Map[String, Int] = Map([("A", 0), ("B", 0), ("C", 1), ("D", 1)])
  let groups = order_levels_by_edges(diagram.nodes, diagram.edges, levels)
  inspect(groups[1][0].id, content="D")
  inspect(groups[1][1].id, content="C")
}

///|
test "measures CJK SVG edge labels by display width" {
  let cjk = svg_edge_label_width("注文", 10.0)
  let ascii = svg_edge_label_width("ab", 10.0)
  inspect(cjk > ascii, content="true")
}

///|
test "reserves an LR lane for a CJK edge label" {
  let diagram = match
    parse(
      "flowchart LR\n  Browser[ブラウザ] -->|注文を送信| API[注文 API]",
    ) {
    Graph(graph) => graph
    _ => abort("expected a graph diagram")
  }
  let layout = layout_graph(diagram, default_ascii_options())
  let browser = layout.nodes[0].box
  let api = layout.nodes[1].box
  let lane = api.x - (browser.x + browser.width)
  inspect(lane >= display_width("注文を送信") + 2, content="true")
}

///|
test "reserves LR label lanes at ASCII, CJK, and emoji width boundaries" {
  let labels = ["a", "1234567890", "注文を送信", "🚀🚀🚀"]
  for label in labels {
    let diagram = match parse("flowchart LR\n  A -->|\{label}| B") {
      Graph(graph) => graph
      _ => abort("expected a graph diagram")
    }
    let layout = layout_graph(diagram, default_ascii_options())
    let left = layout.nodes[0].box
    let right = layout.nodes[1].box
    let lane = right.x - (left.x + left.width)
    inspect(lane >= display_width(label) + 2, content="true")
  }
}

///|
test "wide sibling subgraph labels do not overlap" {
  let diagram = match
    parse(
      "flowchart LR\n  subgraph client[クライアントアプリケーション境界]\n    A\n  end\n  subgraph service[サービス境界]\n    B\n  end\n  A --> B",
    ) {
    Graph(graph) => graph
    _ => abort("expected a graph diagram")
  }
  let layout = layout_graph(diagram, default_ascii_options())
  let first = subgraph_box(
    diagram.subgraphs[0],
    diagram.subgraphs,
    layout.nodes,
  )
  let second = subgraph_box(
    diagram.subgraphs[1],
    diagram.subgraphs,
    layout.nodes,
  )
  match (first, second) {
    (Some(left), Some(right)) => {
      let separated = if left.x <= right.x {
        left.x + left.width < right.x
      } else {
        right.x + right.width < left.x
      }
      inspect(separated, content="true")
    }
    _ => inspect(false, content="true")
  }
}

///|
test "SVG bounds include a wide subgraph frame" {
  let diagram = match
    parse(
      "flowchart LR\n  subgraph client[クライアントアプリケーション境界]\n    A\n  end\n  subgraph service[サービス境界]\n    B\n  end\n  A --> B",
    ) {
    Graph(graph) => graph
    _ => abort("expected a graph diagram")
  }
  let layout = layout_graph(diagram, default_ascii_options())
  let (width, height) = graph_svg_bounds(diagram, layout)
  let first = subgraph_box(
    diagram.subgraphs[0],
    diagram.subgraphs,
    layout.nodes,
  )
  let second = subgraph_box(
    diagram.subgraphs[1],
    diagram.subgraphs,
    layout.nodes,
  )
  match (first, second) {
    (Some(left), Some(right)) => {
      inspect(width >= left.x + left.width, content="true")
      inspect(width >= right.x + right.width, content="true")
      inspect(height >= left.y + left.height, content="true")
      inspect(height >= right.y + right.height, content="true")
    }
    _ => inspect(false, content="true")
  }
}

///|
test "SVG viewport includes the left half of a long TD edge label" {
  match
    parse(
      "flowchart TD\n  A -->|確認と承認を同時に処理するための非常に長い説明| B",
    ) {
    MermaidDiagram::Graph(diagram) => {
      let layout = layout_graph(diagram, default_ascii_options())
      let (min_x, _, _, _) = graph_svg_viewport(diagram, layout)
      assert_true(min_x < 0)
    }
    _ => assert_true(false)
  }
}

///|
test "self loops use a visible curved SVG path" {
  let svg = experimental_render_to_svg("flowchart LR\n  A --> A")
  assert_true(svg.contains(" C "))
}

///|
test "parallel edges receive separate SVG lanes" {
  let svg = experimental_render_to_svg(
    "flowchart LR\n  API -->|注文を作成する| DB\n  API -->|監査ログを記録する| DB",
  )
  assert_true(svg.contains(" C "))
}

///|
test "subgraph labels are drawn above crossing edges" {
  let svg = experimental_render_to_svg(
    "flowchart TD\n  subgraph first[最初のグループ]\n    A\n  end\n  subgraph second[次のグループ]\n    B\n  end\n  A --> B",
  )
  assert_true(svg.contains("<g class=\"subgraph-labels\">"))
}
