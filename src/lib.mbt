///|
pub fn parse_mermaid_text(text : String) -> MermaidDiagram {
  parse_mermaid(text)
}

///|
pub fn canvas_to_string(canvas : Canvas) -> String {
  canvas.render()
}

///|
pub fn render_mermaid_ascii(
  text : String,
  options? : AsciiRenderOptions = default_ascii_options(),
) -> String {
  match parse_mermaid(text) {
    Graph(g) => render_graph_ascii(g, options)
    Sequence(s) => render_sequence_ascii(s, options)
  }
}

///|
pub fn render_mermaid_canvas(
  text : String,
  options? : AsciiRenderOptions = default_ascii_options(),
) -> Canvas {
  match parse_mermaid(text) {
    Graph(g) => render_graph_canvas(g, options)
    Sequence(s) => render_sequence_canvas(s, options)
  }
}

///|
pub fn render_mermaid(
  text : String,
  options? : RenderOptions = default_render_options(),
) -> String {
  match parse_mermaid(text) {
    Graph(g) => render_graph_svg(g, options)
    Sequence(s) => render_sequence_svg(s, options)
  }
}

///|
pub fn from_shiki_theme(theme : @highlight.HighlightTheme) -> DiagramColors {
  from_syntree_theme(theme)
}

///|
pub fn render_options_from_colors(
  colors : DiagramColors,
  font~ : String = "monospace",
  transparent~ : Bool = false,
) -> RenderOptions {
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
