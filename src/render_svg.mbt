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
fn svg_edge_path(start : Point, end_ : Point, direction : Direction) -> String {
  let x1 = to_px_x(start.x)
  let y1 = to_px_y(start.y)
  let x2 = to_px_x(end_.x)
  let y2 = to_px_y(end_.y)
  if x1 == x2 || y1 == y2 {
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
fn svg_open(
  width_px : Double,
  height_px : Double,
  transparent : Bool,
  bg : String,
) -> String {
  let sb = StringBuilder::new()
  sb.write_view(
    "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"\{width_px}\" height=\"\{height_px}\" viewBox=\"0 0 \{width_px} \{height_px}\">\n",
  )
  if not(transparent) {
    sb.write_view(
      "<rect x=\"0\" y=\"0\" width=\"\{width_px}\" height=\"\{height_px}\" fill=\"\{bg}\" />\n",
    )
  }
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
pub fn render_graph_svg(
  diagram : GraphDiagram,
  options : RenderOptions,
) -> String {
  let ascii_opts = default_ascii_options()
  let layout = layout_graph(diagram, ascii_opts)
  let colors = build_colors(options)
  let font = resolve_font(options)
  let transparent = resolve_transparent(options)
  let pad = 20.0
  let width_px = to_px_x(layout.width) + pad * 2
  let height_px = to_px_y(layout.height) + pad * 2
  let font_size = cell_py * 0.8
  let sb = StringBuilder::new()
  sb.write_view(svg_open(width_px, height_px, transparent, colors.bg))
  sb.write_view(arrow_marker_defs(colors.accent))
  sb.write_view("<g transform=\"translate(\{pad},\{pad})\">\n")
  sb.write_view("<g class=\"edges\">\n")
  for edge in layout.edges {
    let path_d = svg_edge_path(edge.start, edge.end, layout.direction)
    sb.write_view(
      "<path d=\"\{path_d}\" fill=\"none\" stroke=\"\{colors.line}\" stroke-width=\"1.5\" marker-end=\"url(#arrow)\" />\n",
    )
    match edge.edge.label {
      Some(label) => {
        let lx = (to_px_x(edge.start.x) + to_px_x(edge.end.x)) / 2.0
        let ly = (to_px_y(edge.start.y) + to_px_y(edge.end.y)) / 2.0
        let text_w = label.length().to_double() * font_size * 0.55
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
        let rx = match pnode.node.shape {
          NodeShape::Rounded => 12
          NodeShape::Circle => (if w < h { w } else { h }).to_int() / 2
          _ => 4
        }
        sb.write_view(
          "<rect x=\"\{x}\" y=\"\{y}\" width=\"\{w}\" height=\"\{h}\" rx=\"\{rx}\" ry=\"\{rx}\" fill=\"\{colors.surface}\" stroke=\"\{colors.border}\" stroke-width=\"1.2\" />\n",
        )
        let mut ty = y + ascii_opts.padding_y.to_double() * cell_py + font_size
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
  sb.write_view("</g>\n")
  sb.write_view("</svg>")
  sb.to_string()
}

///|
pub fn render_sequence_svg(
  diagram : SequenceDiagram,
  options : RenderOptions,
) -> String {
  let ascii_opts = default_ascii_options()
  let layout = layout_sequence(diagram, ascii_opts)
  let colors = build_colors(options)
  let font = resolve_font(options)
  let transparent = resolve_transparent(options)
  let pad = 20.0
  let width_px = to_px_x(layout.width) + pad * 2
  let height_px = to_px_y(layout.height) + pad * 2
  let font_size = cell_py * 0.8
  let sb = StringBuilder::new()
  sb.write_view(svg_open(width_px, height_px, transparent, colors.bg))
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
