///|
let cell_px : Double = 10.0

///|
let cell_py : Double = 18.0

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
      let mut w = content_w + padding_x * 2
      let mut h = content_h + padding_y * 2
      if node.shape == NodeShape::Diamond {
        w += 2
        h += 2
      }
      (w, h)
    }
  }
}

///|
fn compute_levels(
  nodes : Array[GraphNode],
  edges : Array[GraphEdge],
) -> Map[String, Int] {
  let indeg : Map[String, Int] = Map([])
  let adj : Map[String, Array[String]] = Map([])
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
  let levels : Map[String, Int] = Map([])
  let queue : Array[String] = []
  let processed : Map[String, Bool] = Map([])
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
      if !processed.get_or_default(node.id, false) {
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
          if !processed.get_or_default(to, false) {
            let next = base + 1
            let cur = levels.get_or_default(to, 0)
            if next > cur {
              levels.set(to, next)
            }
          }
          let deg = indeg.get_or_default(to, 0) - 1
          indeg.set(to, deg)
          if deg == 0 && !processed.get_or_default(to, false) {
            queue.push(to)
          }
        }
      }
    }
  }
  for node in nodes {
    if !levels.contains(node.id) {
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
  let map : Map[Int, Array[GraphNode]] = Map([])
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
fn cross_positions(groups : Array[Array[GraphNode]]) -> Map[String, Int] {
  let positions : Map[String, Int] = Map([])
  for group in groups {
    for i, node in group {
      positions.set(node.id, i)
    }
  }
  positions
}

///|
fn neighbor_score(
  node : GraphNode,
  edges : Array[GraphEdge],
  positions : Map[String, Int],
  incoming : Bool,
) -> (Int, Int) {
  let mut sum = 0
  let mut count = 0
  for edge in edges {
    let neighbor = if incoming && edge.to == node.id {
      Some(edge.from)
    } else if !incoming && edge.from == node.id {
      Some(edge.to)
    } else {
      None
    }
    match neighbor {
      Some(id) =>
        if positions.contains(id) {
          sum += positions.get_or_default(id, 0)
          count += 1
        }
      None => ()
    }
  }
  (sum, count)
}

///|
fn sort_group_by_neighbors(
  group : Array[GraphNode],
  edges : Array[GraphEdge],
  positions : Map[String, Int],
  incoming : Bool,
) -> Unit {
  group.sort_by(fn(left, right) {
    let (left_sum, left_count) = neighbor_score(
      left, edges, positions, incoming,
    )
    let (right_sum, right_count) = neighbor_score(
      right, edges, positions, incoming,
    )
    if left_count == 0 && right_count == 0 {
      left.id.compare(right.id)
    } else if left_count == 0 {
      1
    } else if right_count == 0 {
      -1
    } else {
      let left_score = left_sum * right_count
      let right_score = right_sum * left_count
      if left_score < right_score {
        -1
      } else if left_score > right_score {
        1
      } else {
        left.id.compare(right.id)
      }
    }
  })
}

///|
/// Orders nodes within each rank by adjacent ranks to reduce edge crossings.
fn order_levels_by_edges(
  nodes : Array[GraphNode],
  edges : Array[GraphEdge],
  levels : Map[String, Int],
) -> Array[Array[GraphNode]] {
  let groups = group_by_level(nodes, levels)
  for group in groups {
    group.sort_by(fn(left, right) { left.id.compare(right.id) })
  }
  let mut positions = cross_positions(groups)
  for i = 1; i < groups.length(); i = i + 1 {
    sort_group_by_neighbors(groups[i], edges, positions, true)
    positions = cross_positions(groups)
  }
  let mut i = groups.length()
  while i > 1 {
    i -= 1
    sort_group_by_neighbors(groups[i - 1], edges, positions, false)
    positions = cross_positions(groups)
  }
  groups
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
/// Returns the deepest subgraph containing a node.
fn node_subgraph_depth(diagram : GraphDiagram, node_id : String) -> Int {
  let mut depth = 0
  for subgraph in diagram.subgraphs {
    for member_id in subgraph.node_ids {
      if member_id == node_id && subgraph.depth + 1 > depth {
        depth = subgraph.depth + 1
      }
    }
  }
  depth
}

///|
/// Returns the maximum nested subgraph depth in a diagram.
fn max_subgraph_depth(diagram : GraphDiagram) -> Int {
  let mut depth = 0
  for subgraph in diagram.subgraphs {
    if subgraph.depth + 1 > depth {
      depth = subgraph.depth + 1
    }
  }
  depth
}

///|
fn layout_graph(diagram : GraphDiagram, options : Options) -> PositionedGraph {
  let padding_x = options.padding_x
  let padding_y = options.padding_y
  let subgraph_offset = if diagram.subgraphs.length() > 0 { 2 } else { 0 }
  let nested_subgraph_offset = max_subgraph_depth(diagram) * 2
  let size_map : Map[String, (Int, Int)] = Map([])
  for n in diagram.nodes {
    size_map.set(n.id, measure_node_size(n, padding_x, padding_y))
  }
  let levels = compute_levels(diagram.nodes, diagram.edges)
  let grouped = order_levels_by_edges(diagram.nodes, diagram.edges, levels)
  let is_vertical = diagram.direction == Direction::TD ||
    diagram.direction == Direction::BT
  let mut gap_main = 2.0
  for edge in diagram.edges {
    match edge.label {
      Some(label) => {
        let required_gap = if is_vertical {
          2.0
        } else {
          (display_width(label) + 2).to_double()
        }
        if required_gap > gap_main {
          gap_main = required_gap
        }
      }
      None => ()
    }
  }
  if !is_vertical {
    for subgraph in diagram.subgraphs {
      let required_gap = (display_width(subgraph.label) + 4).to_double()
      if required_gap > gap_main {
        gap_main = required_gap
      }
    }
  }
  let gap_cross = 4.0
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
  let available_w = if options.max_width > 0 {
    options.max_width.to_double()
  } else {
    10000.0
  }
  let cross_justify : @types.Alignment = if options.max_width > 0 {
    @types.Alignment::SpaceEvenly
  } else {
    @types.Alignment::Center
  }
  let root_align : @types.Alignment = if options.max_width > 0 {
    @types.Alignment::Stretch
  } else {
    @types.Alignment::Center
  }
  let root_style = make_flex_style(
    main_dir,
    main_gap,
    @types.Alignment::Start,
    root_align,
  )
  let level_children : Array[@node.Node] = []
  for i, group in grouped {
    let level_style = make_flex_style(
      cross_dir,
      cross_gap,
      cross_justify,
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
  let crater_layout : @layout_types.Layout = @crater.compute_layout(
    root,
    @types.Size::new(available_w, 10000.0),
  )
  let layout_map : Map[String, LayoutBox] = Map([])
  for level_layout in crater_layout.children {
    for node_layout in level_layout.children {
      layout_map.set(node_layout.id, {
        x: (level_layout.x + node_layout.x).to_int() +
        subgraph_offset +
        node_subgraph_depth(diagram, node_layout.id) * 2,
        y: (level_layout.y + node_layout.y).to_int() + subgraph_offset,
        width: node_layout.width.to_int(),
        height: node_layout.height.to_int(),
      })
    }
  }
  let total_w = crater_layout.width.to_int() +
    subgraph_offset * 2 +
    nested_subgraph_offset
  let total_h = crater_layout.height.to_int() + subgraph_offset * 2
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
/// Calculates the bounding box for a parsed subgraph from positioned members.
fn subgraph_box(
  subgraph : GraphSubgraph,
  subgraphs : Array[GraphSubgraph],
  nodes : Array[PositionedNode],
) -> LayoutBox? {
  let mut found = false
  let mut min_x = 0
  let mut min_y = 0
  let mut max_x = 0
  let mut max_y = 0
  for positioned in nodes {
    let mut is_member = false
    for node_id in subgraph.node_ids {
      if node_id == positioned.node.id {
        is_member = true
      }
    }
    if is_member {
      let box = positioned.box
      if !found {
        found = true
        min_x = box.x
        min_y = box.y
        max_x = box.x + box.width
        max_y = box.y + box.height
      } else {
        if box.x < min_x {
          min_x = box.x
        }
        if box.y < min_y {
          min_y = box.y
        }
        if box.x + box.width > max_x {
          max_x = box.x + box.width
        }
        if box.y + box.height > max_y {
          max_y = box.y + box.height
        }
      }
    }
  }
  if !found {
    None
  } else {
    let x = if min_x > 0 { min_x - 1 } else { 0 }
    let y = if min_y > 0 { min_y - 1 } else { 0 }
    let mut right = max_x + 1
    let mut bottom = max_y + 1
    for child in subgraphs {
      if child.depth <= subgraph.depth {
        continue
      }
      let mut overlaps = false
      for child_id in child.node_ids {
        for parent_id in subgraph.node_ids {
          if child_id == parent_id {
            overlaps = true
          }
        }
      }
      if overlaps {
        match subgraph_box(child, subgraphs, nodes) {
          Some(child_box) => {
            if child_box.x + child_box.width + 1 > right {
              right = child_box.x + child_box.width + 1
            }
            if child_box.y + child_box.height + 1 > bottom {
              bottom = child_box.y + child_box.height + 1
            }
          }
          None => ()
        }
      }
    }
    Some({
      x,
      y,
      width: max_int(right - x, display_width(subgraph.label) + 4),
      height: bottom - y,
    })
  }
}

///|
fn layout_sequence(
  diagram : SequenceDiagram,
  options : Options,
) -> PositionedSequence {
  let padding_x = options.padding_x
  let actor_gap = 6.0
  let top_margin = 0
  let actor_height = 3
  let seq_available_w = if options.max_width > 0 {
    options.max_width.to_double()
  } else {
    10000.0
  }
  let seq_justify : @types.Alignment = if options.max_width > 0 {
    @types.Alignment::SpaceEvenly
  } else {
    @types.Alignment::Start
  }
  let actor_style = make_flex_style(
    @types.FlexDirection::Row,
    @types.Dimension::Length(actor_gap),
    seq_justify,
    @types.Alignment::Start,
  )
  let actor_nodes : Array[@node.Node] = []
  for actor in diagram.actors {
    let w = display_width(actor.label) + padding_x * 2 + 2
    actor_nodes.push(
      @node.Node::leaf(actor.id, make_leaf_style(w, actor_height)),
    )
  }
  let actor_root = @node.Node::new("actors", actor_style, actor_nodes)
  let actor_layout : @layout_types.Layout = @crater.compute_layout(
    actor_root,
    @types.Size::new(seq_available_w, 10000.0),
  )
  let actors : Array[PositionedActor] = []
  let actor_map : Map[String, PositionedActor] = Map([])
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
