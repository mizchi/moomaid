///|
pub let cell_px : Double = 10.0

///|
pub let cell_py : Double = 18.0

///|
fn measure_node_size(
  node : GraphNode,
  padding_x : Int,
  padding_y : Int,
) -> (Int, Int) {
  match node.shape {
    NodeShape::StateStart | NodeShape::StateEnd => (3, 3)
    _ => {
      let mut content_w = 0
      let mut content_h = 0
      let section_count = node.sections.length()
      for section in node.sections {
        content_w = max_int(content_w, max_len(section))
        content_h += section.length()
      }
      if section_count > 1 {
        content_h += section_count - 1
      }
      let w = content_w + padding_x * 2
      let h = content_h + padding_y * 2
      (w, h)
    }
  }
}

///|
fn compute_levels(
  nodes : Array[GraphNode],
  edges : Array[GraphEdge],
) -> Map[String, Int] {
  let indeg : Map[String, Int] = Map::new()
  let adj : Map[String, Array[String]] = Map::new()
  for node in nodes {
    indeg.set(node.id, 0)
  }
  for edge in edges {
    let deg = indeg.get_or_default(edge.to, 0) + 1
    indeg.set(edge.to, deg)
    let list = adj.get_or_default(edge.from, [])
    list.push(edge.to)
    adj.set(edge.from, list)
  }
  let levels : Map[String, Int] = Map::new()
  let queue : Array[String] = []
  let processed : Map[String, Bool] = Map::new()
  for id, deg in indeg {
    if deg == 0 {
      queue.push(id)
    }
  }
  let mut qi = 0
  while qi < queue.length() {
    let id = queue[qi]
    qi += 1
    processed.set(id, true)
    let base = levels.get_or_default(id, 0)
    for to in adj.get_or_default(id, []) {
      let next = base + 1
      let cur = levels.get_or_default(to, 0)
      if next > cur {
        levels.set(to, next)
      }
      let deg = indeg.get_or_default(to, 0) - 1
      indeg.set(to, deg)
      if deg == 0 {
        queue.push(to)
      }
    }
  }
  // Handle cycles: force-process nodes with remaining indegree > 0
  let mut has_remaining = true
  while has_remaining {
    has_remaining = false
    let mut best_id = ""
    let mut best_level = -1
    for node in nodes {
      if not(processed.get_or_default(node.id, false)) {
        has_remaining = true
        let lvl = levels.get_or_default(node.id, 0)
        if best_level < 0 || lvl > best_level {
          best_id = node.id
          best_level = lvl
        }
      }
    }
    if has_remaining {
      queue.push(best_id)
      while qi < queue.length() {
        let id = queue[qi]
        qi += 1
        processed.set(id, true)
        let base = levels.get_or_default(id, 0)
        for to in adj.get_or_default(id, []) {
          if not(processed.get_or_default(to, false)) {
            let next = base + 1
            let cur = levels.get_or_default(to, 0)
            if next > cur {
              levels.set(to, next)
            }
          }
          let deg = indeg.get_or_default(to, 0) - 1
          indeg.set(to, deg)
          if deg == 0 && not(processed.get_or_default(to, false)) {
            queue.push(to)
          }
        }
      }
    }
  }
  for node in nodes {
    if not(levels.contains(node.id)) {
      levels.set(node.id, 0)
    }
  }
  levels
}

///|
fn group_by_level(
  nodes : Array[GraphNode],
  levels : Map[String, Int],
) -> Array[Array[GraphNode]] {
  let map : Map[Int, Array[GraphNode]] = Map::new()
  for node in nodes {
    let level = levels.get_or_default(node.id, 0)
    let list = map.get_or_default(level, [])
    list.push(node)
    map.set(level, list)
  }
  let keys : Array[Int] = []
  for key in map.keys() {
    keys.push(key)
  }
  keys.sort()
  let out : Array[Array[GraphNode]] = []
  for key in keys {
    out.push(map.get_or_default(key, []))
  }
  out
}

///|
fn make_flex_style(
  dir : @types.FlexDirection,
  gap : @types.Dimension,
  justify : @types.Alignment,
  align : @types.Alignment,
) -> @style.Style {
  let s = @style.Style::default()
  s.display = @types.Display::Flex
  s.flex_direction = dir
  s.justify_content = justify
  s.align_items = align
  match dir {
    @types.FlexDirection::Row | @types.FlexDirection::RowReverse =>
      s.column_gap = gap
    @types.FlexDirection::Column | @types.FlexDirection::ColumnReverse =>
      s.row_gap = gap
  }
  s
}

///|
fn make_leaf_style(w : Int, h : Int) -> @style.Style {
  let s = @style.Style::default()
  s.width = @types.Dimension::Length(w.to_double())
  s.height = @types.Dimension::Length(h.to_double())
  s
}

///|
pub fn layout_graph(
  diagram : GraphDiagram,
  options : AsciiRenderOptions,
) -> PositionedGraph {
  let padding_x = options.padding_x
  let padding_y = options.padding_y
  let gap_main = 2.0
  let gap_cross = 4.0
  let size_map : Map[String, (Int, Int)] = Map::new()
  for n in diagram.nodes {
    size_map.set(n.id, measure_node_size(n, padding_x, padding_y))
  }
  let levels = compute_levels(diagram.nodes, diagram.edges)
  let grouped = group_by_level(diagram.nodes, levels)
  let is_vertical = diagram.direction == Direction::TD ||
    diagram.direction == Direction::BT
  let main_dir : @types.FlexDirection = match diagram.direction {
    Direction::TD => @types.FlexDirection::Column
    Direction::BT => @types.FlexDirection::ColumnReverse
    Direction::LR => @types.FlexDirection::Row
    Direction::RL => @types.FlexDirection::RowReverse
  }
  let cross_dir : @types.FlexDirection = if is_vertical {
    @types.FlexDirection::Row
  } else {
    @types.FlexDirection::Column
  }
  let main_gap = @types.Dimension::Length(gap_main)
  let cross_gap = @types.Dimension::Length(gap_cross)
  let root_style = make_flex_style(
    main_dir,
    main_gap,
    @types.Alignment::Start,
    @types.Alignment::Center,
  )
  let level_children : Array[@node.Node] = []
  for i, group in grouped {
    let level_style = make_flex_style(
      cross_dir,
      cross_gap,
      @types.Alignment::Center,
      @types.Alignment::Center,
    )
    let node_children : Array[@node.Node] = []
    for n in group {
      let (w, h) = size_map.get_or_default(n.id, (4, 3))
      node_children.push(@node.Node::leaf(n.id, make_leaf_style(w, h)))
    }
    level_children.push(
      @node.Node::new("level_\{i}", level_style, node_children),
    )
  }
  let root = @node.Node::new("root", root_style, level_children)
  let crater_layout = @crater.compute_layout(
    root,
    @types.Size::new(10000.0, 10000.0),
  )
  let layout_map : Map[String, LayoutBox] = Map::new()
  for level_layout in crater_layout.children {
    for node_layout in level_layout.children {
      layout_map.set(node_layout.id, {
        x: (level_layout.x + node_layout.x).to_int(),
        y: (level_layout.y + node_layout.y).to_int(),
        width: node_layout.width.to_int(),
        height: node_layout.height.to_int(),
      })
    }
  }
  let total_w = crater_layout.width.to_int()
  let total_h = crater_layout.height.to_int()
  let nodes : Array[PositionedNode] = []
  for n in diagram.nodes {
    let box = layout_map.get_or_default(n.id, {
      x: 0,
      y: 0,
      width: 1,
      height: 1,
    })
    nodes.push({ node: n, box })
  }
  let edges : Array[PositionedEdge] = []
  for edge in diagram.edges {
    let fb = layout_map.get_or_default(edge.from, {
      x: 0,
      y: 0,
      width: 1,
      height: 1,
    })
    let tb = layout_map.get_or_default(edge.to, {
      x: 0,
      y: 0,
      width: 1,
      height: 1,
    })
    let (sx, sy, ex, ey) = match diagram.direction {
      Direction::LR =>
        (fb.x + fb.width, fb.y + fb.height / 2, tb.x, tb.y + tb.height / 2)
      Direction::RL =>
        (fb.x, fb.y + fb.height / 2, tb.x + tb.width, tb.y + tb.height / 2)
      Direction::BT =>
        (fb.x + fb.width / 2, fb.y, tb.x + tb.width / 2, tb.y + tb.height)
      Direction::TD =>
        (fb.x + fb.width / 2, fb.y + fb.height, tb.x + tb.width / 2, tb.y)
    }
    edges.push({ edge, start: { x: sx, y: sy }, end: { x: ex, y: ey } })
  }
  {
    nodes,
    edges,
    width: total_w,
    height: total_h,
    direction: diagram.direction,
    kind: diagram.kind,
  }
}

///|
pub fn layout_sequence(
  diagram : SequenceDiagram,
  options : AsciiRenderOptions,
) -> PositionedSequence {
  let padding_x = options.padding_x
  let actor_gap = 6.0
  let top_margin = 0
  let actor_height = 3
  let actor_style = make_flex_style(
    @types.FlexDirection::Row,
    @types.Dimension::Length(actor_gap),
    @types.Alignment::Start,
    @types.Alignment::Start,
  )
  let actor_nodes : Array[@node.Node] = []
  for actor in diagram.actors {
    let w = actor.label.length() + padding_x * 2 + 2
    actor_nodes.push(
      @node.Node::leaf(actor.id, make_leaf_style(w, actor_height)),
    )
  }
  let actor_root = @node.Node::new("actors", actor_style, actor_nodes)
  let actor_layout = @crater.compute_layout(
    actor_root,
    @types.Size::new(10000.0, 10000.0),
  )
  let actors : Array[PositionedActor] = []
  let actor_map : Map[String, PositionedActor] = Map::new()
  for i, actor in diagram.actors {
    if i < actor_layout.children.length() {
      let al = actor_layout.children[i]
      let box = {
        x: al.x.to_int() + 2,
        y: top_margin,
        width: al.width.to_int(),
        height: actor_height,
      }
      let pa : PositionedActor = { actor, box }
      actors.push(pa)
      actor_map.set(actor.id, pa)
    }
  }
  let messages : Array[PositionedMessage] = []
  let mut y = top_margin + actor_height + 1
  for msg in diagram.messages {
    match (actor_map.get(msg.from), actor_map.get(msg.to)) {
      (Some(f), Some(t)) => {
        let start = { x: f.box.x + f.box.width / 2, y }
        let end_ = { x: t.box.x + t.box.width / 2, y }
        messages.push({ message: msg, start, end: end_, y })
        y += 2
      }
      _ => ()
    }
  }
  let width = if actors.length() == 0 {
    10
  } else {
    let last = actors[actors.length() - 1].box
    last.x + last.width + 2
  }
  let height = y
  { actors, messages, width, height }
}
