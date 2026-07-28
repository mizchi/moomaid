///|
/// Returns the text after the first whitespace-separated keyword.
fn directive_value(text : String) -> String {
  match split_once(text, " ") {
    Some((_, value)) => trim_line(value)
    None => ""
  }
}

///|
/// Parses a flowchart subgraph declaration.
fn parse_subgraph_header(text : String, depth : Int) -> GraphSubgraph {
  let node = parse_node_token(directive_value(text), NodeShape::Rect)
  { id: node.id, label: node.label, node_ids: [], depth }
}

///|
/// Finds node identifiers declared by a flowchart line.
fn subgraph_nodes_from_line(text : String) -> Array[String] {
  if text.has_prefix("direction ") ||
    text.has_prefix("style ") ||
    text.has_prefix("classDef ") ||
    text.has_prefix("linkStyle ") {
    return []
  }
  let nodes : Map[String, GraphNode] = Map([])
  let edges : Array[GraphEdge] = []
  parse_edge_chain(text, nodes, edges, NodeShape::Rect)
  if nodes.is_empty() && !text.contains("--") {
    let node = parse_node_token(text, NodeShape::Rect)
    if node.id.length() > 0 {
      nodes.set(node.id, node)
    }
  }
  let ids : Array[String] = []
  for node in nodes.values() {
    ids.push(node.id)
  }
  ids
}

///|
/// Parses flowchart nodes, edges, and one or more nested subgraphs.
fn parse_flowchart_with_subgraphs(
  lines : Array[String],
  header_index : Int,
  direction : Direction,
) -> GraphDiagram {
  let (nodes, edges) = parse_flow_edges(lines, header_index, NodeShape::Rect)
  let subgraphs : Array[GraphSubgraph] = []
  let stack : Array[GraphSubgraph] = []
  for i, line in lines {
    if i <= header_index {
      continue
    }
    let text = trim_line(line)
    if text.length() == 0 || text.has_prefix("%%") {
      continue
    }
    if text.has_prefix("subgraph ") {
      stack.push(parse_subgraph_header(text, stack.length()))
      continue
    }
    if text == "end" {
      match stack.pop() {
        Some(subgraph) => subgraphs.push(subgraph)
        None => ()
      }
      continue
    }
    if stack.length() > 0 {
      let node_ids = subgraph_nodes_from_line(text)
      for index in 0..<stack.length() {
        let group = stack[index]
        let members = group.node_ids
        for node_id in node_ids {
          members.push(node_id)
        }
        stack[index] = {
          id: group.id,
          label: group.label,
          node_ids: members,
          depth: group.depth,
        }
      }
    }
  }
  while stack.length() > 0 {
    match stack.pop() {
      Some(subgraph) => subgraphs.push(subgraph)
      None => ()
    }
  }
  { kind: DiagramKind::Flowchart, direction, nodes, edges, subgraphs }
}

///|
/// Parses Mermaid timeline entries into periods and their events.
fn parse_timeline(lines : Array[String], header_index : Int) -> TimelineDiagram {
  let mut title : String? = None
  let items : Array[TimelineItem] = []
  for i, line in lines {
    if i <= header_index {
      continue
    }
    let text = trim_line(line)
    if text.length() == 0 || text.has_prefix("%%") {
      continue
    }
    if text.has_prefix("title ") {
      title = Some(directive_value(text))
      continue
    }
    if text.has_prefix(":") {
      match items.pop() {
        Some(item) => {
          let events = item.events
          events.push(trim_line(drop_first_char(text)))
          items.push({ period: item.period, events })
        }
        None => ()
      }
      continue
    }
    match split_once(text, ":") {
      Some((period, event)) => {
        let events : Array[String] = []
        for value in event.split(":") {
          let trimmed = trim_line(value.to_owned())
          if trimmed.length() > 0 {
            events.push(trimmed)
          }
        }
        items.push({ period: trim_line(period), events })
      }
      None => ()
    }
  }
  { title, items }
}

///|
fn parse_mindmap(lines : Array[String], header_index : Int) -> OutlineDiagram {
  let items : Array[OutlineItem] = []
  for i, line in lines {
    if i <= header_index {
      continue
    }
    let text = trim_line(line)
    if text.length() == 0 || text.has_prefix("%%") {
      continue
    }
    let depth = (line.length() - text.length()) / 2
    items.push({ depth, label: text })
  }
  { kind: OutlineKind::Mindmap, title: None, items }
}

///|
fn parse_journey(lines : Array[String], header_index : Int) -> OutlineDiagram {
  let mut title : String? = None
  let items : Array[OutlineItem] = []
  for i, line in lines {
    if i <= header_index {
      continue
    }
    let text = trim_line(line)
    if text.length() == 0 || text.has_prefix("%%") {
      continue
    }
    if text.has_prefix("title ") {
      title = Some(directive_value(text))
    } else if text.has_prefix("section ") {
      items.push({ depth: 0, label: directive_value(text) })
    } else {
      items.push({ depth: 1, label: text })
    }
  }
  { kind: OutlineKind::Journey, title, items }
}

///|
fn parse_pie(
  lines : Array[String],
  header_index : Int,
  header : String,
) -> OutlineDiagram {
  let lower = header.to_lower()
  let title = if lower.has_prefix("pie title ") {
    match split_once(header, "title ") {
      Some((_, text)) => Some(trim_line(text))
      None => None
    }
  } else {
    None
  }
  let items : Array[OutlineItem] = []
  for i, line in lines {
    if i <= header_index {
      continue
    }
    let text = trim_line(line)
    if text.length() > 0 && !text.has_prefix("%%") {
      items.push({ depth: 0, label: text })
    }
  }
  { kind: OutlineKind::Pie, title, items }
}

///|
/// Extracts one quoted or unquoted gitGraph command attribute.
fn parse_git_attribute(text : String, key : String) -> String? {
  match split_once(text, key + ":") {
    Some((_, raw_value)) => {
      let value = trim_line(raw_value)
      if value.has_prefix("\"") {
        let quoted = drop_first_char(value)
        match split_once(quoted, "\"") {
          Some((content, _)) => Some(content)
          None => Some(quoted)
        }
      } else {
        let parts = split_ws(value)
        if parts.length() > 0 {
          Some(parts[0])
        } else {
          None
        }
      }
    }
    None => None
  }
}

///|
/// Extracts a Mermaid gitGraph commit identifier.
fn parse_git_commit_id(text : String) -> String {
  parse_git_attribute(text, "id").unwrap_or("commit")
}

///|
/// Parses Mermaid gitGraph branch, checkout, commit, and merge commands.
fn parse_git_graph(
  lines : Array[String],
  header_index : Int,
) -> GitGraphDiagram {
  let events : Array[GitGraphEvent] = []
  let mut current_branch = "main"
  for i, line in lines {
    if i <= header_index {
      continue
    }
    let text = trim_line(line)
    if text.length() == 0 || text.has_prefix("%%") {
      continue
    }
    let lower = text.to_lower()
    if lower.has_prefix("commit") {
      events.push(
        GitGraphEvent::Commit(current_branch, parse_git_commit_id(text)),
      )
    } else if lower.has_prefix("branch ") {
      let branch = directive_value(text)
      events.push(GitGraphEvent::Branch(branch))
    } else if lower.has_prefix("checkout ") || lower.has_prefix("switch ") {
      let branch = directive_value(text)
      current_branch = branch
      events.push(GitGraphEvent::Checkout(branch))
    } else if lower.has_prefix("merge ") {
      events.push(GitGraphEvent::Merge(directive_value(text)))
    }
  }
  { events, }
}

///|
/// Splits a Gantt task descriptor into comma-separated fields.
fn gantt_fields(text : String) -> Array[String] {
  let fields : Array[String] = []
  for raw in text.split(",") {
    fields.push(trim_line(raw.to_owned()))
  }
  fields
}

///|
/// Returns whether a Gantt metadata field is a Mermaid task status.
fn is_gantt_status(value : String) -> Bool {
  let lower = value.to_lower()
  lower == "done" ||
  lower == "active" ||
  lower == "crit" ||
  lower == "milestone"
}

///|
/// Builds a task from optional status/id metadata followed by start and duration.
fn parse_gantt_task(
  section : String?,
  name : String,
  fields : Array[String],
) -> GanttTask? {
  let field_count = fields.length()
  if field_count < 2 {
    return None
  }
  let metadata_count = field_count - 2
  let mut status : String? = None
  for index in 0..<metadata_count {
    if is_gantt_status(fields[index]) {
      status = Some(fields[index])
    }
  }
  Some({
    section,
    name: trim_line(name),
    status,
    start: fields[field_count - 2],
    duration: fields[field_count - 1],
  })
}

///|
/// Parses a useful core subset of Mermaid Gantt syntax.
fn parse_gantt(lines : Array[String], header_index : Int) -> GanttDiagram {
  let mut title : String? = None
  let mut date_format : String? = None
  let mut section : String? = None
  let tasks : Array[GanttTask] = []
  for i, line in lines {
    if i <= header_index {
      continue
    }
    let text = trim_line(line)
    if text.length() == 0 || text.has_prefix("%%") {
      continue
    }
    let lower = text.to_lower()
    if lower.has_prefix("title ") {
      title = Some(directive_value(text))
      continue
    }
    if lower.has_prefix("dateformat ") {
      date_format = Some(directive_value(text))
      continue
    }
    if lower.has_prefix("section ") {
      section = Some(directive_value(text))
      continue
    }
    match split_once(text, ":") {
      Some((name, raw_fields)) => {
        let fields = gantt_fields(raw_fields)
        match parse_gantt_task(section, name, fields) {
          Some(task) => tasks.push(task)
          None => ()
        }
      }
      None => ()
    }
  }
  { title, date_format, tasks }
}
