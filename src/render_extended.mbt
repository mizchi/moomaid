///|
/// Renders sequence extensions in a compact terminal-friendly event stream.
fn render_extended_sequence_ascii(diagram : SequenceDiagram) -> String {
  let sb = StringBuilder::new()
  sb.write_view("sequenceDiagram")
  let actor_labels : Map[String, String] = Map([])
  for actor in diagram.actors {
    actor_labels.set(actor.id, actor.label)
  }
  let mut message_number = 1
  for event in diagram.events {
    sb.write_char('\n')
    match event {
      SequenceEvent::Message(message) => {
        let arrow = if message.dashed { "-->>" } else { "->>" }
        let prefix = if diagram.autonumber { "\{message_number}. " } else { "" }
        let from = actor_labels.get_or_default(message.from, message.from)
        let to = actor_labels.get_or_default(message.to, message.to)
        sb.write_view("\{from} \{arrow} \{to}: \{prefix}\{message.text}")
        message_number += 1
      }
      SequenceEvent::Note(target, text) => {
        let label = actor_labels.get_or_default(target, target)
        sb.write_view("  [note \{label}] \{text}")
      }
      SequenceEvent::Activate(actor) => {
        let label = actor_labels.get_or_default(actor, actor)
        sb.write_view("  [activate \{label}]")
      }
      SequenceEvent::Deactivate(actor) => {
        let label = actor_labels.get_or_default(actor, actor)
        sb.write_view("  [deactivate \{label}]")
      }
      SequenceEvent::BlockStart(kind, label) =>
        sb.write_view("  [\{kind} \{label}]")
      SequenceEvent::BlockElse(label) => sb.write_view("  [else \{label}]")
      SequenceEvent::BlockAnd(label) => sb.write_view("  [and \{label}]")
      SequenceEvent::BlockEnd => sb.write_view("  [end]")
    }
  }
  sb.to_string()
}

///|
/// Renders a Mermaid timeline as an ordered text outline.
fn render_timeline_ascii(diagram : TimelineDiagram) -> String {
  let sb = StringBuilder::new()
  match diagram.title {
    Some(title) => sb.write_view("Timeline: \{title}")
    None => sb.write_view("Timeline")
  }
  for item in diagram.items {
    sb.write_view("\n\{item.period} ●")
    for event in item.events {
      sb.write_view("\n  └─ \{event}")
    }
  }
  sb.to_string()
}

///|
fn render_outline_ascii(diagram : OutlineDiagram) -> String {
  let kind = match diagram.kind {
    OutlineKind::Mindmap => "Mindmap"
    OutlineKind::Journey => "Journey"
    OutlineKind::Pie => "Pie"
  }
  let sb = StringBuilder::new()
  match diagram.title {
    Some(title) => sb.write_view("\{kind}: \{title}")
    None => sb.write_view(kind)
  }
  for item in diagram.items {
    sb.write_string("\n")
    for _ in 0..<item.depth {
      sb.write_string("  ")
    }
    sb.write_view("• \{item.label}")
  }
  sb.to_string()
}

///|
fn render_outline_svg(diagram : OutlineDiagram, options : SvgOptions) -> String {
  render_text_svg(render_outline_ascii(diagram), options)
}

///|
/// Renders gitGraph events while retaining their branch context.
fn render_git_graph_ascii(diagram : GitGraphDiagram) -> String {
  let sb = StringBuilder::new()
  sb.write_view("gitGraph")
  for event in diagram.events {
    sb.write_char('\n')
    match event {
      GitGraphEvent::Commit(branch, id) => sb.write_view("\{branch} ● \{id}")
      GitGraphEvent::Branch(branch) =>
        sb.write_view("  ├─ branch \{branch}")
      GitGraphEvent::Checkout(branch) =>
        sb.write_view("  └─ checkout \{branch}")
      GitGraphEvent::Merge(branch) => sb.write_view("  ◆ merge \{branch}")
    }
  }
  sb.to_string()
}

///|
/// Renders Gantt tasks as a stable terminal table.
fn render_gantt_ascii(diagram : GanttDiagram) -> String {
  let sb = StringBuilder::new()
  match diagram.title {
    Some(title) => sb.write_view("Gantt: \{title}")
    None => sb.write_view("Gantt")
  }
  let mut previous_section : String? = None
  for task in diagram.tasks {
    if task.section != previous_section {
      match task.section {
        Some(section) => sb.write_view("\n[\{section}]")
        None => ()
      }
      previous_section = task.section
    }
    let status = match task.status {
      Some(value) => "[\{value}] "
      None => ""
    }
    sb.write_view("\n\{status}\{task.name} | \{task.start} | \{task.duration}")
  }
  sb.to_string()
}

///|
/// Converts a terminal rendering into a portable SVG text document.
fn render_text_svg(text : String, options : SvgOptions) -> String {
  let lines = split_lines(text)
  let mut columns = 1
  for line in lines {
    columns = max_int(columns, display_width(line))
  }
  let colors = escape_svg_colors(build_colors(options))
  let font = resolve_font(options)
  let transparent = resolve_transparent(options)
  let pad = resolve_svg_padding(options).to_double()
  let width_px = columns.to_double() * cell_px + pad * 2.0
  let height_px = lines.length().to_double() * cell_py + pad * 2.0
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
  let mut y = pad + cell_py * 0.8
  for line in lines {
    sb.write_view(
      "<text x=\"\{pad}\" y=\"\{y}\" font-size=\"\{cell_py * 0.8}\" fill=\"\{colors.fg}\" font-family=\"\{escape_xml(font)}\" xml:space=\"preserve\">\{escape_xml(line)}</text>\n",
    )
    y += cell_py
  }
  sb.write_view("</svg>")
  sb.to_string()
}

///|
/// Renders sequence extensions through the shared terminal SVG representation.
fn render_extended_sequence_svg(
  diagram : SequenceDiagram,
  options : SvgOptions,
) -> String {
  render_text_svg(render_extended_sequence_ascii(diagram), options)
}

///|
/// Renders a timeline through the shared terminal SVG representation.
fn render_timeline_svg(
  diagram : TimelineDiagram,
  options : SvgOptions,
) -> String {
  render_text_svg(render_timeline_ascii(diagram), options)
}

///|
/// Renders a gitGraph through the shared terminal SVG representation.
fn render_git_graph_svg(
  diagram : GitGraphDiagram,
  options : SvgOptions,
) -> String {
  render_text_svg(render_git_graph_ascii(diagram), options)
}

///|
/// Renders a Gantt diagram through the shared terminal SVG representation.
fn render_gantt_svg(diagram : GanttDiagram, options : SvgOptions) -> String {
  render_text_svg(render_gantt_ascii(diagram), options)
}
