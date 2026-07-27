///|
pub fn parse(text : String) -> MermaidDiagram {
  parse_mermaid(text)
}

///|
pub fn render_to_string(
  text : String,
  options? : Options = default_ascii_options(),
) -> String {
  match parse_mermaid(text) {
    Graph(g) => render_graph_ascii(g, options)
    Sequence(s) => render_sequence_ascii(s, options)
    Timeline(t) => render_timeline_ascii(t)
    GitGraph(g) => render_git_graph_ascii(g)
    Gantt(g) => render_gantt_ascii(g)
  }
}

///|
pub fn experimental_render_to_svg(
  text : String,
  options? : SvgOptions = default_render_options(),
) -> String {
  match parse_mermaid(text) {
    Graph(g) => render_graph_svg(g, options)
    Sequence(s) => render_sequence_svg(s, options)
    Timeline(t) => render_timeline_svg(t, options)
    GitGraph(g) => render_git_graph_svg(g, options)
    Gantt(g) => render_gantt_svg(g, options)
  }
}

///|
fn svg_options_from_colors(
  colors : DiagramColors,
  font? : String = "monospace",
  transparent? : Bool = false,
) -> SvgOptions {
  {
    bg: Some(colors.bg),
    fg: Some(colors.fg),
    line: Some(colors.line),
    accent: Some(colors.accent),
    muted: Some(colors.muted),
    surface: Some(colors.surface),
    border: Some(colors.border),
    font: Some(font),
    transparent: Some(transparent),
  }
}

///|
pub fn svg_options_from_theme(
  name : String,
  font? : String = "monospace",
  transparent? : Bool = false,
) -> SvgOptions? {
  match themes.get(name) {
    Some(colors) => Some(svg_options_from_colors(colors, font~, transparent~))
    None => None
  }
}
