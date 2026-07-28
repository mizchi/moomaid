///|
fn escape_xml(text : String) -> String {
  let sb = StringBuilder::new()
  for c in text {
    match c {
      '&' => sb.write_view("&amp;")
      '<' => sb.write_view("&lt;")
      '>' => sb.write_view("&gt;")
      '"' => sb.write_view("&quot;")
      '\'' => sb.write_view("&apos;")
      _ => sb.write_char(c)
    }
  }
  sb.to_string()
}

///|
fn escape_svg_colors(colors : DiagramColors) -> DiagramColors {
  {
    bg: escape_xml(colors.bg),
    fg: escape_xml(colors.fg),
    line: escape_xml(colors.line),
    accent: escape_xml(colors.accent),
    muted: escape_xml(colors.muted),
    surface: escape_xml(colors.surface),
    border: escape_xml(colors.border),
  }
}

///|
fn arrow_marker_defs(color : String) -> String {
  "<defs>\n  <marker id=\"arrow\" markerWidth=\"8\" markerHeight=\"8\" refX=\"7\" refY=\"4\" orient=\"auto\" markerUnits=\"strokeWidth\">\n    <path d=\"M0,0 L8,4 L0,8 z\" fill=\"\{color}\" />\n  </marker>\n</defs>\n"
}

///|
fn to_px_x(x : Int) -> Double {
  x.to_double() * cell_px
}

///|
fn to_px_y(y : Int) -> Double {
  y.to_double() * cell_py
}

///|
fn same_edge_lane(left : GraphEdge, right : GraphEdge) -> Bool {
  (left.from == right.from && left.to == right.to) ||
  (left.from == right.to && left.to == right.from)
}

///|
fn edge_lane_offset(edges : Array[PositionedEdge], index : Int) -> Double {
  let target = edges[index].edge
  let mut count = 0
  let mut rank = 0
  for i, candidate in edges {
    if same_edge_lane(target, candidate.edge) {
      if i < index {
        rank += 1
      }
      count += 1
    }
  }
  if count <= 1 {
    0.0
  } else {
    (rank.to_double() - (count - 1).to_double() / 2.0) * 32.0
  }
}

///|
fn svg_edge_label_position(
  start : Point,
  end_ : Point,
  direction : Direction,
  lane_offset : Double,
) -> (Double, Double) {
  let x = (to_px_x(start.x) + to_px_x(end_.x)) / 2.0
  let y = (to_px_y(start.y) + to_px_y(end_.y)) / 2.0
  match direction {
    Direction::TD | Direction::BT => (x + lane_offset * 0.75, y)
    Direction::LR | Direction::RL => (x, y + lane_offset * 0.75)
  }
}

///|
fn svg_edge_path(
  start : Point,
  end_ : Point,
  direction : Direction,
  lane_offset : Double,
  self_loop : Bool,
) -> String {
  let x1 = to_px_x(start.x)
  let y1 = to_px_y(start.y)
  let x2 = to_px_x(end_.x)
  let y2 = to_px_y(end_.y)
  if self_loop {
    let outer_x = if x1 > x2 { x1 } else { x2 }
    let loop_x = outer_x + 42.0
    let loop_top = y1 - 36.0
    let loop_bottom = y1 + 36.0
    let return_x = outer_x + 14.0
    "M \{outer_x} \{y1} C \{loop_x} \{loop_top}, \{loop_x} \{loop_bottom}, \{return_x} \{y1}"
  } else if lane_offset != 0.0 {
    match direction {
      Direction::TD | Direction::BT => {
        let mid_y = (y1 + y2) / 2.0
        "M \{x1} \{y1} C \{x1 + lane_offset} \{mid_y}, \{x2 + lane_offset} \{mid_y}, \{x2} \{y2}"
      }
      Direction::LR | Direction::RL => {
        let mid_x = (x1 + x2) / 2.0
        "M \{x1} \{y1} C \{mid_x} \{y1 + lane_offset}, \{mid_x} \{y2 + lane_offset}, \{x2} \{y2}"
      }
    }
  } else if x1 == x2 || y1 == y2 {
    "M \{x1} \{y1} L \{x2} \{y2}"
  } else {
    match direction {
      Direction::TD | Direction::BT => {
        let mid_y = (y1 + y2) / 2.0
        "M \{x1} \{y1} C \{x1} \{mid_y}, \{x2} \{mid_y}, \{x2} \{y2}"
      }
      Direction::LR | Direction::RL => {
        let mid_x = (x1 + x2) / 2.0
        "M \{x1} \{y1} C \{mid_x} \{y1}, \{mid_x} \{y2}, \{x2} \{y2}"
      }
    }
  }
}

///|
fn svg_edge_label_width(label : String, font_size : Double) -> Double {
  display_width(label).to_double() * font_size * 0.55
}

///|
fn graph_svg_viewport(
  diagram : GraphDiagram,
  layout : PositionedGraph,
) -> (Double, Double, Double, Double) {
  let mut min_x = 0.0
  let mut min_y = 0.0
  let mut max_x = to_px_x(layout.width)
  let mut max_y = to_px_y(layout.height)
  let font_size = cell_py * 0.8
  for index, edge in layout.edges {
    let lane_offset = edge_lane_offset(layout.edges, index)
    let x1 = to_px_x(edge.start.x)
    let y1 = to_px_y(edge.start.y)
    let x2 = to_px_x(edge.end.x)
    let y2 = to_px_y(edge.end.y)
    if edge.edge.from == edge.edge.to {
      let outer_x = if x1 > x2 { x1 } else { x2 }
      let loop_x = outer_x + 42.0
      let loop_top = y1 - 36.0
      let loop_bottom = y1 + 36.0
      if loop_x > max_x {
        max_x = loop_x
      }
      if loop_top < min_y {
        min_y = loop_top
      }
      if loop_bottom > max_y {
        max_y = loop_bottom
      }
    } else {
      let path_min_x = if x1 < x2 { x1 } else { x2 }
      let path_max_x = if x1 > x2 { x1 } else { x2 }
      let path_min_y = if y1 < y2 { y1 } else { y2 }
      let path_max_y = if y1 > y2 { y1 } else { y2 }
      if path_min_x < min_x {
        min_x = path_min_x
      }
      if path_max_x > max_x {
        max_x = path_max_x
      }
      if path_min_y < min_y {
        min_y = path_min_y
      }
      if path_max_y > max_y {
        max_y = path_max_y
      }
      if lane_offset != 0.0 {
        match layout.direction {
          Direction::TD | Direction::BT => {
            let control_x1 = x1 + lane_offset
            let control_x2 = x2 + lane_offset
            if control_x1 < min_x {
              min_x = control_x1
            }
            if control_x2 < min_x {
              min_x = control_x2
            }
            if control_x1 > max_x {
              max_x = control_x1
            }
            if control_x2 > max_x {
              max_x = control_x2
            }
          }
          Direction::LR | Direction::RL => {
            let control_y1 = y1 + lane_offset
            let control_y2 = y2 + lane_offset
            if control_y1 < min_y {
              min_y = control_y1
            }
            if control_y2 < min_y {
              min_y = control_y2
            }
            if control_y1 > max_y {
              max_y = control_y1
            }
            if control_y2 > max_y {
              max_y = control_y2
            }
          }
        }
      }
    }
    match edge.edge.label {
      Some(label) => {
        let (label_x, label_y) = svg_edge_label_position(
          edge.start,
          edge.end,
          layout.direction,
          lane_offset,
        )
        let text_w = svg_edge_label_width(label, font_size)
        let text_h = font_size * 1.2
        let left = label_x - text_w / 2.0 - 4.0
        let right = label_x + text_w / 2.0 + 4.0
        let top = label_y - text_h / 2.0 - 2.0
        let bottom = label_y + text_h / 2.0 + 2.0
        if left < min_x {
          min_x = left
        }
        if right > max_x {
          max_x = right
        }
        if top < min_y {
          min_y = top
        }
        if bottom > max_y {
          max_y = bottom
        }
      }
      None => ()
    }
  }
  for subgraph in diagram.subgraphs {
    match subgraph_box(subgraph, diagram.subgraphs, layout.nodes) {
      Some(box) => {
        let right = to_px_x(box.x + box.width)
        let bottom = to_px_y(box.y + box.height)
        if right > max_x {
          max_x = right
        }
        if bottom > max_y {
          max_y = bottom
        }
      }
      None => ()
    }
  }
  (min_x, min_y, max_x - min_x, max_y - min_y)
}

///|
fn graph_svg_bounds(
  diagram : GraphDiagram,
  layout : PositionedGraph,
) -> (Int, Int) {
  let (_, _, width, height) = graph_svg_viewport(diagram, layout)
  ((width / cell_px).ceil().to_int(), (height / cell_py).ceil().to_int())
}

///|
fn svg_open(
  width_px : Double,
  height_px : Double,
  transparent : Bool,
  bg : String,
  title : String?,
  description : String?,
) -> String {
  let sb = StringBuilder::new()
  sb.write_view(
    "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"\{width_px}\" height=\"\{height_px}\" viewBox=\"0 0 \{width_px} \{height_px}\" role=\"img\"",
  )
  match (title, description) {
    (Some(_), Some(_)) =>
      sb.write_view(" aria-labelledby=\"moomaid-title moomaid-description\"")
    (Some(_), None) => sb.write_view(" aria-labelledby=\"moomaid-title\"")
    (None, Some(_)) =>
      sb.write_view(
        " aria-label=\"Mermaid diagram\" aria-describedby=\"moomaid-description\"",
      )
    (None, None) => sb.write_view(" aria-label=\"Mermaid diagram\"")
  }
  sb.write_view(">")
  match title {
    Some(text) =>
      sb.write_view("<title id=\"moomaid-title\">\{escape_xml(text)}</title>")
    None => ()
  }
  match description {
    Some(text) =>
      sb.write_view(
        "<desc id=\"moomaid-description\">\{escape_xml(text)}</desc>",
      )
    None => ()
  }
  sb.write_view("\n")
  if !transparent {
    sb.write_view(
      "<rect x=\"0\" y=\"0\" width=\"\{width_px}\" height=\"\{height_px}\" fill=\"\{bg}\" />\n",
    )
  }
  sb.to_string()
}

///|
priv enum DebugBoxKind {
  Node(String)
  EdgeLabel(Int)
  SubgraphLabel
  Collision
}

///|
priv struct DebugBox {
  x : Double
  y : Double
  width : Double
  height : Double
  kind : DebugBoxKind
}

///|
priv struct DebugPoint {
  px : Double
  py : Double
}

///|
fn debug_box_intersection(left : DebugBox, right : DebugBox) -> DebugBox? {
  let left_x = if left.x > right.x { left.x } else { right.x }
  let top_y = if left.y > right.y { left.y } else { right.y }
  let left_right = left.x + left.width
  let right_right = right.x + right.width
  let right_x = if left_right < right_right { left_right } else { right_right }
  let left_bottom = left.y + left.height
  let right_bottom = right.y + right.height
  let bottom_y = if left_bottom < right_bottom {
    left_bottom
  } else {
    right_bottom
  }
  if left_x < right_x && top_y < bottom_y {
    Some({
      x: left_x,
      y: top_y,
      width: right_x - left_x,
      height: bottom_y - top_y,
      kind: DebugBoxKind::Collision,
    })
  } else {
    None
  }
}

///|
fn debug_point_in_box(point : DebugPoint, box : DebugBox) -> Bool {
  point.px >= box.x &&
  point.px <= box.x + box.width &&
  point.py >= box.y &&
  point.py <= box.y + box.height
}

///|
fn debug_cross(
  first : DebugPoint,
  second : DebugPoint,
  third : DebugPoint,
) -> Double {
  (second.px - first.px) * (third.py - first.py) -
  (second.py - first.py) * (third.px - first.px)
}

///|
fn debug_point_on_segment(
  point : DebugPoint,
  start : DebugPoint,
  end_ : DebugPoint,
) -> Bool {
  point.px >= (if start.px < end_.px { start.px } else { end_.px }) &&
  point.px <= (if start.px > end_.px { start.px } else { end_.px }) &&
  point.py >= (if start.py < end_.py { start.py } else { end_.py }) &&
  point.py <= (if start.py > end_.py { start.py } else { end_.py })
}

///|
fn debug_segments_intersect(
  first_start : DebugPoint,
  first_end : DebugPoint,
  second_start : DebugPoint,
  second_end : DebugPoint,
) -> Bool {
  let first_a = debug_cross(first_start, first_end, second_start)
  let first_b = debug_cross(first_start, first_end, second_end)
  let second_a = debug_cross(second_start, second_end, first_start)
  let second_b = debug_cross(second_start, second_end, first_end)
  if first_a == 0.0 &&
    debug_point_on_segment(second_start, first_start, first_end) {
    true
  } else if first_b == 0.0 &&
    debug_point_on_segment(second_end, first_start, first_end) {
    true
  } else if second_a == 0.0 &&
    debug_point_on_segment(first_start, second_start, second_end) {
    true
  } else if second_b == 0.0 &&
    debug_point_on_segment(first_end, second_start, second_end) {
    true
  } else {
    ((first_a > 0.0 && first_b < 0.0) || (first_a < 0.0 && first_b > 0.0)) &&
    ((second_a > 0.0 && second_b < 0.0) || (second_a < 0.0 && second_b > 0.0))
  }
}

///|
fn debug_segment_hits_box(
  start : DebugPoint,
  end_ : DebugPoint,
  box : DebugBox,
) -> Bool {
  if debug_point_in_box(start, box) || debug_point_in_box(end_, box) {
    return true
  }
  let top_left : DebugPoint = { px: box.x, py: box.y }
  let top_right : DebugPoint = { px: box.x + box.width, py: box.y }
  let bottom_left : DebugPoint = { px: box.x, py: box.y + box.height }
  let bottom_right : DebugPoint = {
    px: box.x + box.width,
    py: box.y + box.height,
  }
  debug_segments_intersect(start, end_, top_left, top_right) ||
  debug_segments_intersect(start, end_, top_right, bottom_right) ||
  debug_segments_intersect(start, end_, bottom_right, bottom_left) ||
  debug_segments_intersect(start, end_, bottom_left, top_left)
}

///|
fn debug_cubic_point(
  start : DebugPoint,
  control_one : DebugPoint,
  control_two : DebugPoint,
  end_ : DebugPoint,
  t : Double,
) -> DebugPoint {
  let u = 1.0 - t
  {
    px: u * u * u * start.px +
    3.0 * u * u * t * control_one.px +
    3.0 * u * t * t * control_two.px +
    t * t * t * end_.px,
    py: u * u * u * start.py +
    3.0 * u * u * t * control_one.py +
    3.0 * u * t * t * control_two.py +
    t * t * t * end_.py,
  }
}

///|
fn debug_edge_curve(
  edge : PositionedEdge,
  direction : Direction,
  lane_offset : Double,
) -> (DebugPoint, DebugPoint, DebugPoint, DebugPoint) {
  let x1 = to_px_x(edge.start.x)
  let y1 = to_px_y(edge.start.y)
  let x2 = to_px_x(edge.end.x)
  let y2 = to_px_y(edge.end.y)
  if edge.edge.from == edge.edge.to {
    let outer_x = if x1 > x2 { x1 } else { x2 }
    (
      { px: outer_x, py: y1 },
      { px: outer_x + 42.0, py: y1 - 36.0 },
      { px: outer_x + 42.0, py: y1 + 36.0 },
      { px: outer_x + 14.0, py: y1 },
    )
  } else {
    match direction {
      Direction::TD | Direction::BT => {
        let mid_y = (y1 + y2) / 2.0
        (
          { px: x1, py: y1 },
          { px: x1 + lane_offset, py: mid_y },
          { px: x2 + lane_offset, py: mid_y },
          { px: x2, py: y2 },
        )
      }
      Direction::LR | Direction::RL => {
        let mid_x = (x1 + x2) / 2.0
        (
          { px: x1, py: y1 },
          { px: mid_x, py: y1 + lane_offset },
          { px: mid_x, py: y2 + lane_offset },
          { px: x2, py: y2 },
        )
      }
    }
  }
}

///|
fn debug_edge_hits_box(
  edge : PositionedEdge,
  direction : Direction,
  lane_offset : Double,
  box : DebugBox,
) -> Bool {
  let (start, control_one, control_two, end_) = debug_edge_curve(
    edge, direction, lane_offset,
  )
  let mut previous = start
  let mut i = 1
  while i <= 16 {
    let point = debug_cubic_point(
      start,
      control_one,
      control_two,
      end_,
      i.to_double() / 16.0,
    )
    if debug_segment_hits_box(previous, point, box) {
      return true
    }
    previous = point
    i += 1
  }
  false
}

///|
fn debug_edge_owns_box(
  edge : PositionedEdge,
  edge_index : Int,
  box : DebugBox,
) -> Bool {
  match box.kind {
    DebugBoxKind::Node(node_id) =>
      edge.edge.from == node_id || edge.edge.to == node_id
    DebugBoxKind::EdgeLabel(index) => edge_index == index
    _ => false
  }
}

///|
fn debug_layout_boxes(
  diagram : GraphDiagram,
  layout : PositionedGraph,
  font_size : Double,
) -> Array[DebugBox] {
  let boxes : Array[DebugBox] = []
  for node in layout.nodes {
    let box = node.box
    boxes.push({
      x: to_px_x(box.x),
      y: to_px_y(box.y),
      width: to_px_x(box.width),
      height: to_px_y(box.height),
      kind: DebugBoxKind::Node(node.node.id),
    })
  }
  for index, edge in layout.edges {
    match edge.edge.label {
      Some(label) => {
        let lane_offset = edge_lane_offset(layout.edges, index)
        let (x, y) = svg_edge_label_position(
          edge.start,
          edge.end,
          layout.direction,
          lane_offset,
        )
        let text_w = svg_edge_label_width(label, font_size)
        let text_h = font_size * 1.2
        boxes.push({
          x: x - text_w / 2.0 - 4.0,
          y: y - text_h / 2.0 - 2.0,
          width: text_w + 8.0,
          height: text_h + 4.0,
          kind: DebugBoxKind::EdgeLabel(index),
        })
      }
      None => ()
    }
  }
  for subgraph in diagram.subgraphs {
    match subgraph_box(subgraph, diagram.subgraphs, layout.nodes) {
      Some(box) => {
        let text_w = svg_edge_label_width(subgraph.label, font_size)
        let text_h = font_size * 1.2
        boxes.push({
          x: to_px_x(box.x) + 4.0,
          y: to_px_y(box.y) + 2.0,
          width: text_w + 8.0,
          height: text_h + 4.0,
          kind: DebugBoxKind::SubgraphLabel,
        })
      }
      None => ()
    }
  }
  boxes
}

///|
fn debug_layout_collisions(
  layout : PositionedGraph,
  boxes : Array[DebugBox],
) -> Array[DebugBox] {
  let collisions : Array[DebugBox] = []
  let mut i = 0
  while i < boxes.length() {
    let mut j = i + 1
    while j < boxes.length() {
      match debug_box_intersection(boxes[i], boxes[j]) {
        Some(collision) => collisions.push(collision)
        None => ()
      }
      j += 1
    }
    i += 1
  }
  for edge_index, edge in layout.edges {
    let lane_offset = edge_lane_offset(layout.edges, edge_index)
    for box in boxes {
      if !debug_edge_owns_box(edge, edge_index, box) &&
        debug_edge_hits_box(edge, layout.direction, lane_offset, box) {
        collisions.push({
          x: box.x,
          y: box.y,
          width: box.width,
          height: box.height,
          kind: DebugBoxKind::Collision,
        })
      }
    }
  }
  for first_index, first in layout.edges {
    let mut second_index = first_index + 1
    while second_index < layout.edges.length() {
      let second = layout.edges[second_index]
      let share_node = first.edge.from == second.edge.from ||
        first.edge.from == second.edge.to ||
        first.edge.to == second.edge.from ||
        first.edge.to == second.edge.to
      if !share_node {
        let first_lane = edge_lane_offset(layout.edges, first_index)
        let second_lane = edge_lane_offset(layout.edges, second_index)
        let (first_start, first_control_one, first_control_two, first_end) = debug_edge_curve(
          first,
          layout.direction,
          first_lane,
        )
        let (second_start, second_control_one, second_control_two, second_end) = debug_edge_curve(
          second,
          layout.direction,
          second_lane,
        )
        let mut previous_first = first_start
        let mut first_step = 1
        let mut found_intersection = false
        while first_step <= 16 && !found_intersection {
          let current_first = debug_cubic_point(
            first_start,
            first_control_one,
            first_control_two,
            first_end,
            first_step.to_double() / 16.0,
          )
          let mut previous_second = second_start
          let mut second_step = 1
          while second_step <= 16 && !found_intersection {
            let current_second = debug_cubic_point(
              second_start,
              second_control_one,
              second_control_two,
              second_end,
              second_step.to_double() / 16.0,
            )
            if debug_segments_intersect(
                previous_first, current_first, previous_second, current_second,
              ) {
              collisions.push({
                x: (current_first.px + current_second.px) / 2.0 - 4.0,
                y: (current_first.py + current_second.py) / 2.0 - 4.0,
                width: 8.0,
                height: 8.0,
                kind: DebugBoxKind::Collision,
              })
              found_intersection = true
            }
            previous_second = current_second
            second_step += 1
          }
          previous_first = current_first
          first_step += 1
        }
      }
      second_index += 1
    }
  }
  collisions
}

///|
fn render_debug_layout_svg(
  diagram : GraphDiagram,
  layout : PositionedGraph,
  font_size : Double,
) -> String {
  let boxes = debug_layout_boxes(diagram, layout, font_size)
  let collisions = debug_layout_collisions(layout, boxes)
  let sb = StringBuilder::new()
  sb.write_view("<g class=\"debug-layout\" pointer-events=\"none\">\n")
  for index, edge in layout.edges {
    let lane_offset = edge_lane_offset(layout.edges, index)
    let path_d = svg_edge_path(
      edge.start,
      edge.end,
      layout.direction,
      lane_offset,
      edge.edge.from == edge.edge.to,
    )
    sb.write_view(
      "<path class=\"debug-edge-path\" d=\"\{path_d}\" fill=\"none\" stroke=\"#F59E0B\" stroke-width=\"1\" stroke-dasharray=\"3,2\" opacity=\"0.85\" />\n",
    )
  }
  for box in boxes {
    match box.kind {
      DebugBoxKind::Node(_) =>
        sb.write_view(
          "<rect class=\"debug-node-box\" x=\"\{box.x}\" y=\"\{box.y}\" width=\"\{box.width}\" height=\"\{box.height}\" fill=\"#93C5FD\" fill-opacity=\"0.12\" stroke=\"#2563EB\" stroke-width=\"1\" />\n",
        )
      DebugBoxKind::EdgeLabel(_) =>
        sb.write_view(
          "<rect class=\"debug-edge-label-box\" x=\"\{box.x}\" y=\"\{box.y}\" width=\"\{box.width}\" height=\"\{box.height}\" fill=\"#86EFAC\" fill-opacity=\"0.12\" stroke=\"#16A34A\" stroke-width=\"1\" />\n",
        )
      DebugBoxKind::SubgraphLabel =>
        sb.write_view(
          "<rect class=\"debug-subgraph-label-box\" x=\"\{box.x}\" y=\"\{box.y}\" width=\"\{box.width}\" height=\"\{box.height}\" fill=\"#C4B5FD\" fill-opacity=\"0.12\" stroke=\"#7C3AED\" stroke-width=\"1\" />\n",
        )
      DebugBoxKind::Collision => ()
    }
  }
  for collision in collisions {
    sb.write_view(
      "<rect class=\"debug-collision\" x=\"\{collision.x}\" y=\"\{collision.y}\" width=\"\{collision.width}\" height=\"\{collision.height}\" fill=\"#FCA5A5\" fill-opacity=\"0.45\" stroke=\"#DC2626\" stroke-width=\"1.5\" />\n",
    )
  }
  sb.write_view("</g>\n")
  sb.to_string()
}

///|
fn svg_state_circle(
  cx : Double,
  cy : Double,
  r : Double,
  accent : String,
  filled : Bool,
) -> String {
  let sb = StringBuilder::new()
  if filled {
    sb.write_view(
      "<circle cx=\"\{cx}\" cy=\"\{cy}\" r=\"\{r}\" fill=\"\{accent}\" />\n",
    )
  } else {
    sb.write_view(
      "<circle cx=\"\{cx}\" cy=\"\{cy}\" r=\"\{r}\" fill=\"none\" stroke=\"\{accent}\" stroke-width=\"1.5\" />\n",
    )
    sb.write_view(
      "<circle cx=\"\{cx}\" cy=\"\{cy}\" r=\"\{r * 0.55}\" fill=\"\{accent}\" />\n",
    )
  }
  sb.to_string()
}

///|
fn render_graph_svg(diagram : GraphDiagram, options : SvgOptions) -> String {
  let ascii_opts = default_ascii_options()
  let layout = layout_graph(diagram, ascii_opts)
  let colors = escape_svg_colors(build_colors(options))
  let font = escape_xml(resolve_font(options))
  let transparent = resolve_transparent(options)
  let pad = resolve_svg_padding(options).to_double()
  let (min_x, min_y, render_width, render_height) = graph_svg_viewport(
    diagram, layout,
  )
  let (bounds_width, bounds_height) = graph_svg_bounds(diagram, layout)
  let content_width = if render_width > to_px_x(bounds_width) {
    render_width
  } else {
    to_px_x(bounds_width)
  }
  let content_height = if render_height > to_px_y(bounds_height) {
    render_height
  } else {
    to_px_y(bounds_height)
  }
  let width_px = content_width + pad * 2
  let height_px = content_height + pad * 2
  let font_size = cell_py * 0.8
  let sb = StringBuilder::new()
  sb.write_view(
    svg_open(
      width_px,
      height_px,
      transparent,
      colors.bg,
      options.title,
      options.description,
    ),
  )
  sb.write_view(arrow_marker_defs(colors.accent))
  let translate_x = pad - min_x
  let translate_y = pad - min_y
  sb.write_view("<g transform=\"translate(\{translate_x},\{translate_y})\">\n")
  sb.write_view("<g class=\"subgraphs\">\n")
  for subgraph in diagram.subgraphs {
    match subgraph_box(subgraph, diagram.subgraphs, layout.nodes) {
      Some(box) => {
        let x = to_px_x(box.x)
        let y = to_px_y(box.y)
        let w = to_px_x(box.width)
        let h = to_px_y(box.height)
        sb.write_view(
          "<rect x=\"\{x}\" y=\"\{y}\" width=\"\{w}\" height=\"\{h}\" rx=\"8\" ry=\"8\" fill=\"none\" stroke=\"\{colors.muted}\" stroke-width=\"1\" stroke-dasharray=\"4,3\" />\n",
        )
      }
      None => ()
    }
  }
  sb.write_view("</g>\n")
  sb.write_view("<g class=\"edges\">\n")
  for index, edge in layout.edges {
    let lane_offset = edge_lane_offset(layout.edges, index)
    let path_d = svg_edge_path(
      edge.start,
      edge.end,
      layout.direction,
      lane_offset,
      edge.edge.from == edge.edge.to,
    )
    sb.write_view(
      "<path d=\"\{path_d}\" fill=\"none\" stroke=\"\{colors.line}\" stroke-width=\"1.5\" marker-end=\"url(#arrow)\" />\n",
    )
    match edge.edge.label {
      Some(label) => {
        let (lx, ly) = svg_edge_label_position(
          edge.start,
          edge.end,
          layout.direction,
          lane_offset,
        )
        let text_w = svg_edge_label_width(label, font_size)
        let text_h = font_size * 1.2
        sb.write_view(
          "<rect x=\"\{lx - text_w / 2.0 - 4.0}\" y=\"\{ly - text_h / 2.0 - 2.0}\" width=\"\{text_w + 8.0}\" height=\"\{text_h + 4.0}\" rx=\"3\" fill=\"\{colors.bg}\" />\n",
        )
        sb.write_view(
          "<text x=\"\{lx}\" y=\"\{ly}\" font-size=\"\{font_size}\" fill=\"\{colors.muted}\" text-anchor=\"middle\" dominant-baseline=\"central\" font-family=\"\{font}\">\{escape_xml(label)}</text>\n",
        )
      }
      None => ()
    }
  }
  sb.write_view("</g>\n")
  sb.write_view("<g class=\"subgraph-labels\">\n")
  for subgraph in diagram.subgraphs {
    match subgraph_box(subgraph, diagram.subgraphs, layout.nodes) {
      Some(box) => {
        let x = to_px_x(box.x)
        let y = to_px_y(box.y)
        let label_w = svg_edge_label_width(subgraph.label, font_size)
        let label_h = font_size * 1.2
        sb.write_view(
          "<rect x=\"\{x + 4.0}\" y=\"\{y + 2.0}\" width=\"\{label_w + 8.0}\" height=\"\{label_h + 4.0}\" rx=\"3\" fill=\"\{colors.bg}\" />\n",
        )
        sb.write_view(
          "<text x=\"\{x + 8.0}\" y=\"\{y + cell_py * 0.8}\" font-size=\"\{font_size}\" fill=\"\{colors.muted}\" font-family=\"\{font}\">\{escape_xml(subgraph.label)}</text>\n",
        )
      }
      None => ()
    }
  }
  sb.write_view("</g>\n")
  sb.write_view("<g class=\"nodes\">\n")
  for pnode in layout.nodes {
    let b = pnode.box
    let x = to_px_x(b.x)
    let y = to_px_y(b.y)
    let w = to_px_x(b.width)
    let h = to_px_y(b.height)
    sb.write_view("<g id=\"\{escape_xml(pnode.node.id)}\">\n")
    match pnode.node.shape {
      NodeShape::StateStart => {
        let cx = x + w / 2.0
        let cy = y + h / 2.0
        let r = (if w < h { w } else { h }) / 2.2
        sb.write_view(svg_state_circle(cx, cy, r, colors.accent, true))
      }
      NodeShape::StateEnd => {
        let cx = x + w / 2.0
        let cy = y + h / 2.0
        let r = (if w < h { w } else { h }) / 2.2
        sb.write_view(svg_state_circle(cx, cy, r, colors.accent, false))
      }
      _ => {
        if pnode.node.shape == NodeShape::Diamond {
          sb.write_view(
            "<polygon points=\"\{x + w / 2.0},\{y} \{x + w},\{y + h / 2.0} \{x + w / 2.0},\{y + h} \{x},\{y + h / 2.0}\" fill=\"\{colors.surface}\" stroke=\"\{colors.border}\" stroke-width=\"1.2\" />\n",
          )
        } else {
          let rx = match pnode.node.shape {
            NodeShape::Rounded => 12
            NodeShape::Circle => (if w < h { w } else { h }).to_int() / 2
            _ => 4
          }
          sb.write_view(
            "<rect x=\"\{x}\" y=\"\{y}\" width=\"\{w}\" height=\"\{h}\" rx=\"\{rx}\" ry=\"\{rx}\" fill=\"\{colors.surface}\" stroke=\"\{colors.border}\" stroke-width=\"1.2\" />\n",
          )
        }
        let mut ty = y + ascii_opts.padding_y.to_double() * cell_py + font_size
        if pnode.node.shape == NodeShape::Diamond {
          ty += cell_py
        }
        let tx = x + ascii_opts.padding_x.to_double() * cell_px
        let mut section_index = 0
        for section in pnode.node.sections {
          for line in section {
            sb.write_view(
              "<text x=\"\{tx}\" y=\"\{ty}\" font-size=\"\{font_size}\" fill=\"\{colors.fg}\" font-family=\"\{font}\">\{escape_xml(line)}</text>\n",
            )
            ty += cell_py
          }
          if section_index < pnode.node.sections.length() - 1 {
            sb.write_view(
              "<line x1=\"\{x + 4}\" y1=\"\{ty - font_size * 0.5}\" x2=\"\{x + w - 4}\" y2=\"\{ty - font_size * 0.5}\" stroke=\"\{colors.border}\" stroke-width=\"1\" stroke-opacity=\"0.5\" />\n",
            )
            ty += cell_py * 0.2
          }
          section_index += 1
        }
      }
    }
    sb.write_view("</g>\n")
  }
  sb.write_view("</g>\n")
  if resolve_debug_layout(options) {
    sb.write_view(render_debug_layout_svg(diagram, layout, font_size))
  }
  sb.write_view("</g>\n")
  sb.write_view("</svg>")
  sb.to_string()
}

///|
fn render_sequence_svg(
  diagram : SequenceDiagram,
  options : SvgOptions,
) -> String {
  if diagram.has_extended_syntax {
    return render_extended_sequence_svg(diagram, options)
  }
  let ascii_opts = default_ascii_options()
  let layout = layout_sequence(diagram, ascii_opts)
  let colors = escape_svg_colors(build_colors(options))
  let font = escape_xml(resolve_font(options))
  let transparent = resolve_transparent(options)
  let pad = resolve_svg_padding(options).to_double()
  let width_px = to_px_x(layout.width) + pad * 2
  let height_px = to_px_y(layout.height) + pad * 2
  let font_size = cell_py * 0.8
  let sb = StringBuilder::new()
  sb.write_view(
    svg_open(
      width_px,
      height_px,
      transparent,
      colors.bg,
      options.title,
      options.description,
    ),
  )
  sb.write_view(arrow_marker_defs(colors.accent))
  sb.write_view("<g transform=\"translate(\{pad},\{pad})\">\n")
  sb.write_view("<g class=\"lifelines\">\n")
  for actor in layout.actors {
    let b = actor.box
    let cx = to_px_x(b.x) + to_px_x(b.width) / 2.0
    let y_start = to_px_y(b.y) + to_px_y(b.height)
    let y_end = to_px_y(layout.height)
    sb.write_view(
      "<line x1=\"\{cx}\" y1=\"\{y_start}\" x2=\"\{cx}\" y2=\"\{y_end}\" stroke=\"\{colors.line}\" stroke-width=\"1\" stroke-dasharray=\"4,3\" />\n",
    )
  }
  sb.write_view("</g>\n")
  sb.write_view("<g class=\"actors\">\n")
  for actor in layout.actors {
    let b = actor.box
    let x = to_px_x(b.x)
    let y = to_px_y(b.y)
    let w = to_px_x(b.width)
    let h = to_px_y(b.height)
    sb.write_view(
      "<rect x=\"\{x}\" y=\"\{y}\" width=\"\{w}\" height=\"\{h}\" rx=\"6\" ry=\"6\" fill=\"\{colors.surface}\" stroke=\"\{colors.border}\" stroke-width=\"1.2\" />\n",
    )
    let tx = x + w / 2.0
    let ty = y + h / 2.0
    sb.write_view(
      "<text x=\"\{tx}\" y=\"\{ty}\" font-size=\"\{font_size}\" fill=\"\{colors.fg}\" font-family=\"\{font}\" text-anchor=\"middle\" dominant-baseline=\"central\">\{escape_xml(actor.actor.label)}</text>\n",
    )
  }
  sb.write_view("</g>\n")
  sb.write_view("<g class=\"messages\">\n")
  for msg in layout.messages {
    let x1 = to_px_x(msg.start.x)
    let y1 = to_px_y(msg.start.y)
    let x2 = to_px_x(msg.end.x)
    let y2 = to_px_y(msg.end.y)
    let dash = if msg.message.dashed { " stroke-dasharray=\"5,3\"" } else { "" }
    sb.write_view(
      "<line x1=\"\{x1}\" y1=\"\{y1}\" x2=\"\{x2}\" y2=\"\{y2}\" stroke=\"\{colors.line}\" stroke-width=\"1.2\" marker-end=\"url(#arrow)\"\{dash} />\n",
    )
    if msg.message.text.length() > 0 {
      let tx = (x1 + x2) / 2.0
      let ty = y1 - font_size * 0.5
      let text_w = msg.message.text.length().to_double() * font_size * 0.55
      sb.write_view(
        "<rect x=\"\{tx - text_w / 2.0 - 3.0}\" y=\"\{ty - font_size * 0.6}\" width=\"\{text_w + 6.0}\" height=\"\{font_size * 1.2}\" rx=\"2\" fill=\"\{colors.bg}\" fill-opacity=\"0.85\" />\n",
      )
      sb.write_view(
        "<text x=\"\{tx}\" y=\"\{ty}\" font-size=\"\{font_size}\" fill=\"\{colors.muted}\" text-anchor=\"middle\" font-family=\"\{font}\">\{escape_xml(msg.message.text)}</text>\n",
      )
    }
  }
  sb.write_view("</g>\n")
  sb.write_view("</g>\n")
  sb.write_view("</svg>")
  sb.to_string()
}
