///|
fn first_non_empty_line(lines : Array[String]) -> (Int, String) {
  for i, line in lines {
    let t = trim_line(line)
    if t.length() > 0 {
      return (i, t)
    }
  }
  (0, "")
}

///|
fn first_non_empty_line_with_column(
  lines : Array[String],
) -> (Int, String, Int) {
  for i, line in lines {
    let text = trim_line(line)
    if text.length() > 0 {
      return (i, text, line.length() - text.length() + 1)
    }
  }
  (0, "", 1)
}

///|
fn is_supported_diagram_header(header : String) -> Bool {
  let lower = header.to_lower()
  lower.has_prefix("sequencediagram") ||
  lower.has_prefix("timeline") ||
  lower.has_prefix("gitgraph") ||
  lower.has_prefix("gantt") ||
  lower.has_prefix("classdiagram") ||
  lower.has_prefix("erdiagram") ||
  lower.has_prefix("statediagram") ||
  lower.has_prefix("mindmap") ||
  lower.has_prefix("journey") ||
  lower.has_prefix("pie") ||
  lower.has_prefix("graph") ||
  lower.has_prefix("flowchart")
}

///|
fn is_flowchart_header(header : String) -> Bool {
  let lower = header.to_lower()
  lower.has_prefix("graph") || lower.has_prefix("flowchart")
}

///|
fn header_name(header : String) -> String {
  match split_once(header, " ") {
    Some((name, _)) => name
    None => header
  }
}

///|
fn trailing_flowchart_arrow(text : String) -> String? {
  let trimmed = trim_line(text)
  if trimmed.has_suffix("-->") {
    Some("-->")
  } else if trimmed.has_suffix("->") {
    Some("->")
  } else if trimmed.has_suffix("--") {
    Some("--")
  } else {
    None
  }
}

///|
fn validate_mermaid(text : String) -> Result[Unit, ParseDiagnostic] {
  let lines = split_lines(text)
  let (header_index, header, header_column) = first_non_empty_line_with_column(
    lines,
  )
  if header.length() == 0 {
    return Err({
      line: 1,
      column: 1,
      message: "expected a Mermaid diagram header",
    })
  }
  if !is_supported_diagram_header(header) {
    return Err({
      line: header_index + 1,
      column: header_column,
      message: "unsupported Mermaid diagram type: " + header_name(header),
    })
  }
  if is_flowchart_header(header) {
    let subgraph_starts : Array[(Int, Int)] = []
    for i, line in lines {
      if i <= header_index {
        continue
      }
      let trimmed = trim_line(line)
      if trimmed.length() == 0 || trimmed.has_prefix("%%") {
        continue
      }
      let column = line.length() - trimmed.length() + 1
      if trimmed.has_prefix("subgraph ") {
        subgraph_starts.push((i, column))
        continue
      }
      if trimmed == "end" {
        match subgraph_starts.pop() {
          Some(_) => ()
          None =>
            return Err({
              line: i + 1,
              column,
              message: "unexpected 'end' without a matching subgraph",
            })
        }
        continue
      }
      match trailing_flowchart_arrow(trimmed) {
        Some(arrow) =>
          return Err({
            line: i + 1,
            column: line.length() + 1,
            message: "expected a target node after '" + arrow + "'",
          })
        None => ()
      }
    }
    match subgraph_starts.pop() {
      Some((line, column)) =>
        return Err({ line: line + 1, column, message: "unterminated subgraph" })
      None => ()
    }
  }
  Ok(())
}

///|
fn parse_direction_from_header(header : String) -> Direction {
  let parts = split_ws(header)
  if parts.length() >= 2 {
    match parts[1].to_upper() {
      "TD" => Direction::TD
      "TB" => Direction::TD
      "LR" => Direction::LR
      "RL" => Direction::RL
      "BT" => Direction::BT
      _ => Direction::TD
    }
  } else {
    Direction::TD
  }
}

///|
fn parse_node_token_without_decision(
  token : String,
  default_shape : NodeShape,
) -> GraphNode {
  let t = trim_line(token)
  match split_once(t, "[") {
    Some((id_raw, rest)) =>
      match split_once(rest, "]") {
        Some((label_raw, _)) => {
          let id = trim_line(id_raw)
          let label = strip_quotes(trim_line(label_raw))
          let sections = [[label]]
          { id, label, shape: NodeShape::Rect, sections }
        }
        None => {
          let id = trim_line(id_raw)
          let sections = [[id]]
          { id, label: id, shape: NodeShape::Rect, sections }
        }
      }
    None =>
      match split_once(t, "((") {
        Some((id_raw, rest)) =>
          match split_once(rest, "))") {
            Some((label_raw, _)) => {
              let id = trim_line(id_raw)
              let label = trim_line(label_raw)
              let sections = [[label]]
              { id, label, shape: NodeShape::Circle, sections }
            }
            None => {
              let id = trim_line(id_raw)
              let sections = [[id]]
              { id, label: id, shape: NodeShape::Circle, sections }
            }
          }
        None =>
          match split_once(t, "(") {
            Some((id_raw, rest)) =>
              match split_once(rest, ")") {
                Some((label_raw, _)) => {
                  let id = trim_line(id_raw)
                  let label = trim_line(label_raw)
                  let sections = [[label]]
                  { id, label, shape: NodeShape::Rounded, sections }
                }
                None => {
                  let id = trim_line(id_raw)
                  let sections = [[id]]
                  { id, label: id, shape: NodeShape::Rounded, sections }
                }
              }
            None => {
              let id = trim_line(t)
              let sections = [[id]]
              { id, label: id, shape: default_shape, sections }
            }
          }
      }
  }
}

///|
/// Parses flowchart decision nodes written as `id{label}`.
fn parse_node_token(token : String, default_shape : NodeShape) -> GraphNode {
  let text = trim_line(token)
  match split_once(text, "{") {
    Some((id_raw, rest)) =>
      match split_once(rest, "}") {
        Some((label_raw, _)) => {
          let id = trim_line(id_raw)
          let label = strip_quotes(trim_line(label_raw))
          { id, label, shape: NodeShape::Diamond, sections: [[label]] }
        }
        None => parse_node_token_without_decision(text, default_shape)
      }
    None => parse_node_token_without_decision(text, default_shape)
  }
}

///|
fn upsert_node(map : Map[String, GraphNode], node : GraphNode) -> Unit {
  match map.get(node.id) {
    None => map.set(node.id, node)
    Some(existing) => {
      let mut shape = existing.shape
      if existing.shape == NodeShape::Rect && node.shape != NodeShape::Rect {
        shape = node.shape
      }
      let mut label = existing.label
      if existing.label == existing.id && node.label != existing.id {
        label = node.label
      }
      let sections = if (
          existing.label != existing.id || existing.sections.length() > 1
        ) &&
        node.label == node.id {
        existing.sections
      } else if node.sections.length() > 0 {
        node.sections
      } else {
        existing.sections
      }
      map.set(node.id, { id: existing.id, label, shape, sections })
    }
  }
}

///|
fn parse_edge_label_and_target(raw : String) -> (String, String?) {
  let right = trim_line(raw)
  if right.has_prefix("|") {
    let rest = drop_first_char(right)
    match split_once(rest, "|") {
      Some((label_raw, target_raw)) => {
        let label = trim_line(label_raw)
        let target = trim_line(target_raw)
        (target, Some(label))
      }
      None => (right, None)
    }
  } else {
    (right, None)
  }
}

///|
fn parse_edge_chain(
  line : String,
  nodes : Map[String, GraphNode],
  edges : Array[GraphEdge],
  default_shape : NodeShape,
) -> Unit {
  let mut remaining = trim_line(line)
  let mut prev_node : GraphNode? = None
  let mut prev_label : String? = None
  while true {
    let arrow = if remaining.contains("-->") {
      "-->"
    } else if remaining.contains("->") {
      "->"
    } else if remaining.contains("--") {
      "--"
    } else {
      ""
    }
    if arrow.length() == 0 {
      let node = parse_node_token(remaining, default_shape)
      upsert_node(nodes, node)
      match prev_node {
        Some(prev) =>
          edges.push({ from: prev.id, to: node.id, label: prev_label })
        None => ()
      }
      break
    }
    match split_once(remaining, arrow) {
      Some((left_raw, right_raw)) => {
        let left = match split_once(left_raw, "--") {
          Some((fst, _)) => fst
          None => left_raw
        }
        let node = parse_node_token(left, default_shape)
        upsert_node(nodes, node)
        match prev_node {
          Some(prev) =>
            edges.push({ from: prev.id, to: node.id, label: prev_label })
          None => ()
        }
        let (right_token, label) = parse_edge_label_and_target(right_raw)
        prev_node = Some(node)
        prev_label = label
        remaining = right_token
      }
      None => break
    }
  }
}

///|
fn parse_flow_edges(
  lines : Array[String],
  header_index : Int,
  default_shape : NodeShape,
) -> (Array[GraphNode], Array[GraphEdge]) {
  let nodes : Map[String, GraphNode] = Map([])
  let edges : Array[GraphEdge] = []
  for i, line in lines {
    if i <= header_index {
      continue
    }
    let t = trim_line(line)
    if t.length() == 0 ||
      t.has_prefix("%%") ||
      t.has_prefix("subgraph ") ||
      t == "end" ||
      t.has_prefix("direction ") ||
      t.has_prefix("style ") ||
      t.has_prefix("classDef ") ||
      t.has_prefix("linkStyle ") {
      continue
    }
    parse_edge_chain(t, nodes, edges, default_shape)
  }
  let nodes_array = Array::from_iter(nodes.values())
  (nodes_array, edges)
}

///|
fn parse_state(
  lines : Array[String],
  header_index : Int,
  direction : Direction,
) -> GraphDiagram {
  let nodes : Map[String, GraphNode] = Map([])
  let edges : Array[GraphEdge] = []
  let mut start_counter = 0
  let mut end_counter = 0
  for i, line in lines {
    if i <= header_index {
      continue
    }
    let t = trim_line(line)
    if t.length() == 0 || t.has_prefix("%%") {
      continue
    }
    if t == "}" {
      continue
    }
    match split_once(t, "state ") {
      Some((prefix, rest)) => {
        if prefix.trim().length() == 0 {
          if rest.contains("{") {
            match split_once(rest, "{") {
              Some((name_raw, _)) => {
                let name = trim_line(name_raw)
                let node = parse_node_token(name, NodeShape::Rounded)
                upsert_node(nodes, node)
                ()
              }
              None => ()
            }
          } else if rest.contains(" as ") {
            match split_once(rest, " as ") {
              Some((label_raw, id_raw)) => {
                let label = strip_quotes(label_raw)
                let id = trim_line(id_raw)
                let sections = [[label]]
                upsert_node(nodes, {
                  id,
                  label,
                  shape: NodeShape::Rounded,
                  sections,
                })
                ()
              }
              None => ()
            }
          }
          continue
        }
        ()
      }
      None => ()
    }
    match split_once(t, " : ") {
      Some((id_raw, label_raw)) => {
        let id = trim_line(id_raw)
        let label = trim_line(label_raw)
        let sections = [[label]]
        upsert_node(nodes, { id, label, shape: NodeShape::Rounded, sections })
        continue
      }
      None => ()
    }
    let arrow = if t.contains("-->") {
      "-->"
    } else if t.contains("->") {
      "->"
    } else {
      ""
    }
    if arrow.length() > 0 {
      match split_once(t, arrow) {
        Some((left_raw, right_raw)) => {
          let left_token = trim_line(left_raw)
          let (right_token, label) = parse_edge_label_and_target(right_raw)
          let left_node = if left_token == "[*]" {
            start_counter += 1
            let id = "_state_start_\{start_counter}"
            { id, label: "", shape: NodeShape::StateStart, sections: [[""]] }
          } else {
            parse_node_token(left_token, NodeShape::Rounded)
          }
          let right_node = if right_token == "[*]" {
            end_counter += 1
            let id = "_state_end_\{end_counter}"
            { id, label: "", shape: NodeShape::StateEnd, sections: [[""]] }
          } else {
            parse_node_token(right_token, NodeShape::Rounded)
          }
          upsert_node(nodes, left_node)
          upsert_node(nodes, right_node)
          edges.push({ from: left_node.id, to: right_node.id, label })
          ()
        }
        None => ()
      }
    }
  }
  let nodes_array = Array::from_iter(nodes.values())
  {
    kind: DiagramKind::State,
    direction,
    nodes: nodes_array,
    edges,
    subgraphs: [],
  }
}

///|
fn parse_flowchart(
  lines : Array[String],
  header_index : Int,
  direction : Direction,
) -> GraphDiagram {
  parse_flowchart_with_subgraphs(lines, header_index, direction)
}

///|
fn parse_class(lines : Array[String], header_index : Int) -> GraphDiagram {
  let nodes : Map[String, GraphNode] = Map([])
  let edges : Array[GraphEdge] = []
  let mut current_class : String? = None
  for i, line in lines {
    if i <= header_index {
      continue
    }
    let t = trim_line(line)
    if t.length() == 0 || t.has_prefix("%%") {
      continue
    }
    if t == "}" {
      current_class = None
      continue
    }
    if t.has_prefix("class ") {
      let parts = split_ws(t)
      if parts.length() >= 2 {
        let id = parts[1]
        let sections = [[id], []]
        upsert_node(nodes, { id, label: id, shape: NodeShape::Rect, sections })
        if t.contains("{") {
          current_class = Some(id)
        }
      }
      continue
    }
    match current_class {
      Some(id) => {
        let member_line = t
        let node = nodes
          .get(id)
          .unwrap_or({
            id,
            label: id,
            shape: NodeShape::Rect,
            sections: [[id], []],
          })
        let sections = node.sections
        if sections.length() == 1 {
          sections.push([])
        }
        sections[1].push(member_line)
        nodes.set(id, { id, label: node.label, shape: node.shape, sections })
        continue
      }
      None => ()
    }
    match split_once(t, ":") {
      Some((left_raw, right_raw)) => {
        let id = trim_line(left_raw)
        let member_line = trim_line(right_raw)
        let node = nodes
          .get(id)
          .unwrap_or({
            id,
            label: id,
            shape: NodeShape::Rect,
            sections: [[id], []],
          })
        let sections = node.sections
        if sections.length() == 1 {
          sections.push([])
        }
        sections[1].push(member_line)
        nodes.set(id, { id, label: node.label, shape: node.shape, sections })
        continue
      }
      None => ()
    }
    let parts = split_ws(t)
    if parts.length() >= 3 && parts[1].contains("--") {
      let from = parts[0]
      let to = parts[2]
      let left = parse_node_token(from, NodeShape::Rect)
      let right = parse_node_token(to, NodeShape::Rect)
      upsert_node(nodes, left)
      upsert_node(nodes, right)
      edges.push({ from, to, label: None })
      continue
    }
  }
  let nodes_array = Array::from_iter(nodes.values())
  {
    kind: DiagramKind::Class,
    direction: Direction::TD,
    nodes: nodes_array,
    edges,
    subgraphs: [],
  }
}

///|
fn parse_er(lines : Array[String], header_index : Int) -> GraphDiagram {
  let nodes : Map[String, GraphNode] = Map([])
  let edges : Array[GraphEdge] = []
  let mut current_entity : String? = None
  for i, line in lines {
    if i <= header_index {
      continue
    }
    let t = trim_line(line)
    if t.length() == 0 || t.has_prefix("%%") {
      continue
    }
    if t == "}" {
      current_entity = None
      continue
    }
    if t.contains("--") {
      let (left, label_opt) = match split_once(t, ":") {
        Some((l, r)) => (l, Some(trim_line(r)))
        None => (t, None)
      }
      let parts = split_ws(left)
      if parts.length() >= 3 {
        let from = parts[0]
        let cardinality = parts[1]
        let to = parts[2]
        let left_node = parse_node_token(from, NodeShape::Rect)
        let right_node = parse_node_token(to, NodeShape::Rect)
        upsert_node(nodes, left_node)
        upsert_node(nodes, right_node)
        let label = match label_opt {
          Some(text) => Some("\{cardinality} \{text}")
          None => Some(cardinality)
        }
        edges.push({ from, to, label })
      }
      continue
    }
    if t.has_suffix("{") {
      let parts = split_ws(t)
      if parts.length() >= 1 {
        let id = parts[0]
        let sections = [[id], []]
        upsert_node(nodes, { id, label: id, shape: NodeShape::Rect, sections })
        current_entity = Some(id)
      }
      continue
    }
    match current_entity {
      Some(id) => {
        let attr_line = t
        let node = nodes
          .get(id)
          .unwrap_or({
            id,
            label: id,
            shape: NodeShape::Rect,
            sections: [[id], []],
          })
        let sections = node.sections
        if sections.length() == 1 {
          sections.push([])
        }
        sections[1].push(attr_line)
        nodes.set(id, { id, label: node.label, shape: node.shape, sections })
        continue
      }
      None => ()
    }
    ()
  }
  let nodes_array = Array::from_iter(nodes.values())
  {
    kind: DiagramKind::Er,
    direction: Direction::TD,
    nodes: nodes_array,
    edges,
    subgraphs: [],
  }
}

///|
fn ensure_actor(
  map : Map[String, SequenceActor],
  id : String,
  kind : ActorKind,
) -> Unit {
  match map.get(id) {
    None => {
      map.set(id, { id, label: id, kind })
      ()
    }
    Some(existing) => {
      if existing.kind == ActorKind::Participant && kind == ActorKind::Actor {
        map.set(id, { id, label: existing.label, kind })
      }
      ()
    }
  }
}

///|
/// Adds or updates an explicitly declared sequence actor.
fn define_actor(
  map : Map[String, SequenceActor],
  id : String,
  label : String,
  kind : ActorKind,
) -> Unit {
  map.set(id, { id, label, kind })
}

///|
/// Parses `participant id as Label` and `actor id as Label` declarations.
fn parse_actor_declaration(text : String) -> (String, String) {
  match split_once(text, " ") {
    Some((_, raw)) =>
      match split_once(raw, " as ") {
        Some((id, label)) => (trim_line(id), strip_quotes(trim_line(label)))
        None => {
          let id = trim_line(raw)
          (id, id)
        }
      }
    None => ("", "")
  }
}

///|
/// Parses a sequence note target and text.
fn parse_sequence_note(text : String) -> (String, String)? {
  match split_once(text, ":") {
    Some((target_raw, note_raw)) => {
      let parts = split_ws(target_raw)
      if parts.length() == 0 {
        None
      } else {
        Some((parts[parts.length() - 1], trim_line(note_raw)))
      }
    }
    None => None
  }
}

///|
fn parse_sequence(lines : Array[String], header_index : Int) -> SequenceDiagram {
  let actors : Map[String, SequenceActor] = Map([])
  let messages : Array[SequenceMessage] = []
  let events : Array[SequenceEvent] = []
  let mut autonumber = false
  let mut has_extended_syntax = false
  for i, line in lines {
    if i <= header_index {
      continue
    }
    let t = trim_line(line)
    if t.length() == 0 || t.has_prefix("%%") {
      continue
    }
    if t.has_prefix("participant ") || t.has_prefix("actor ") {
      let (id, label) = parse_actor_declaration(t)
      if id.length() > 0 {
        let kind = if t.has_prefix("actor ") {
          ActorKind::Actor
        } else {
          ActorKind::Participant
        }
        define_actor(actors, id, label, kind)
      }
      continue
    }
    let lower = t.to_lower()
    if lower.has_prefix("autonumber") {
      autonumber = true
      has_extended_syntax = true
      continue
    }
    if lower.has_prefix("note ") {
      match parse_sequence_note(t) {
        Some((target, text)) => {
          events.push(SequenceEvent::Note(target, text))
          has_extended_syntax = true
        }
        None => ()
      }
      continue
    }
    if lower.has_prefix("activate ") {
      match split_once(t, " ") {
        Some((_, actor)) => {
          events.push(SequenceEvent::Activate(trim_line(actor)))
          has_extended_syntax = true
        }
        None => ()
      }
      continue
    }
    if lower.has_prefix("deactivate ") {
      match split_once(t, " ") {
        Some((_, actor)) => {
          events.push(SequenceEvent::Deactivate(trim_line(actor)))
          has_extended_syntax = true
        }
        None => ()
      }
      continue
    }
    if lower == "end" {
      events.push(SequenceEvent::BlockEnd)
      has_extended_syntax = true
      continue
    }
    if lower.has_prefix("else") {
      let label = match split_once(t, " ") {
        Some((_, rest)) => trim_line(rest)
        None => ""
      }
      events.push(SequenceEvent::BlockElse(label))
      has_extended_syntax = true
      continue
    }
    if lower.has_prefix("and ") {
      let label = match split_once(t, " ") {
        Some((_, rest)) => trim_line(rest)
        None => ""
      }
      events.push(SequenceEvent::BlockAnd(label))
      has_extended_syntax = true
      continue
    }
    if lower.has_prefix("loop ") ||
      lower.has_prefix("alt ") ||
      lower.has_prefix("opt ") ||
      lower.has_prefix("par ") ||
      lower.has_prefix("critical ") ||
      lower.has_prefix("break ") ||
      lower.has_prefix("rect ") {
      match split_once(t, " ") {
        Some((kind, label)) => {
          events.push(
            SequenceEvent::BlockStart(trim_line(kind), trim_line(label)),
          )
          has_extended_syntax = true
        }
        None => ()
      }
      continue
    }
    let arrow = if t.contains("-->>") {
      "-->>"
    } else if t.contains("->>") {
      "->>"
    } else if t.contains("-->") {
      "-->"
    } else if t.contains("->") {
      "->"
    } else {
      ""
    }
    if arrow.length() > 0 {
      match split_once(t, arrow) {
        Some((left_raw, right_raw)) => {
          let dashed = arrow.contains("--")
          let from = trim_line(left_raw)
          let mut text = ""
          let mut to = right_raw
          match split_once(right_raw, ":") {
            Some((to_raw, text_raw)) => {
              to = to_raw
              text = trim_line(text_raw)
            }
            None => ()
          }
          let to_raw = trim_line(to)
          let (to_id, activation) = if to_raw.has_prefix("+") {
            (trim_line(drop_first_char(to_raw)), Some(true))
          } else if to_raw.has_prefix("-") {
            (trim_line(drop_first_char(to_raw)), Some(false))
          } else {
            (to_raw, None)
          }
          ensure_actor(actors, from, ActorKind::Participant)
          ensure_actor(actors, to_id, ActorKind::Participant)
          let message = { from, to: to_id, text, dashed }
          messages.push(message)
          events.push(SequenceEvent::Message(message))
          match activation {
            Some(true) => {
              events.push(SequenceEvent::Activate(to_id))
              has_extended_syntax = true
            }
            Some(false) => {
              events.push(SequenceEvent::Deactivate(to_id))
              has_extended_syntax = true
            }
            None => ()
          }
          ()
        }
        None => ()
      }
    }
  }
  let actors_array = Array::from_iter(actors.values())
  { actors: actors_array, messages, events, autonumber, has_extended_syntax }
}

///|
fn parse_mermaid(text : String) -> MermaidDiagram {
  let lines = split_lines(text)
  let (header_index, header) = first_non_empty_line(lines)
  let header_lower = header.to_lower()
  if header_lower.has_prefix("sequencediagram") {
    Sequence(parse_sequence(lines, header_index))
  } else if header_lower.has_prefix("mindmap") {
    Outline(parse_mindmap(lines, header_index))
  } else if header_lower.has_prefix("journey") {
    Outline(parse_journey(lines, header_index))
  } else if header_lower.has_prefix("pie") {
    Outline(parse_pie(lines, header_index, header))
  } else if header_lower.has_prefix("timeline") {
    Timeline(parse_timeline(lines, header_index))
  } else if header_lower.has_prefix("gitgraph") {
    GitGraph(parse_git_graph(lines, header_index))
  } else if header_lower.has_prefix("gantt") {
    Gantt(parse_gantt(lines, header_index))
  } else if header_lower.has_prefix("classdiagram") {
    Graph(parse_class(lines, header_index))
  } else if header_lower.has_prefix("erdiagram") {
    Graph(parse_er(lines, header_index))
  } else if header_lower.has_prefix("statediagram") {
    let direction = parse_direction_from_header(header)
    Graph(parse_state(lines, header_index, direction))
  } else if header_lower.has_prefix("graph") ||
    header_lower.has_prefix("flowchart") {
    let direction = parse_direction_from_header(header)
    Graph(parse_flowchart(lines, header_index, direction))
  } else {
    let direction = parse_direction_from_header(header)
    Graph(parse_flowchart(lines, header_index, direction))
  }
}

///|
fn parse_mermaid_checked(
  text : String,
) -> Result[MermaidDiagram, ParseDiagnostic] {
  match validate_mermaid(text) {
    Ok(_) => Ok(parse_mermaid(text))
    Err(error) => Err(error)
  }
}
