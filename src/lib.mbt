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
