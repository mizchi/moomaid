///|
pub fn parse(text : String) -> MermaidDiagram {
  parse_mermaid(text)
}

///|
pub fn parse_checked(text : String) -> Result[MermaidDiagram, ParseDiagnostic] {
  parse_mermaid_checked(text)
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
    Outline(d) => render_outline_ascii(d)
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
    Outline(d) => render_outline_svg(d, options)
  }
}

///|
pub fn default_svg_options() -> SvgOptions {
  default_render_options()
}

///|
pub fn SvgOptions::with_background(
  self : SvgOptions,
  background : String,
) -> SvgOptions {
  {
    bg: Some(background),
    fg: self.fg,
    line: self.line,
    accent: self.accent,
    muted: self.muted,
    surface: self.surface,
    border: self.border,
    font: self.font,
    transparent: self.transparent,
    padding: self.padding,
    title: self.title,
    description: self.description,
    debug_layout: self.debug_layout,
  }
}

///|
pub fn SvgOptions::with_font(self : SvgOptions, font : String) -> SvgOptions {
  {
    bg: self.bg,
    fg: self.fg,
    line: self.line,
    accent: self.accent,
    muted: self.muted,
    surface: self.surface,
    border: self.border,
    font: Some(font),
    transparent: self.transparent,
    padding: self.padding,
    title: self.title,
    description: self.description,
    debug_layout: self.debug_layout,
  }
}

///|
pub fn SvgOptions::with_padding(self : SvgOptions, padding : Int) -> SvgOptions {
  {
    bg: self.bg,
    fg: self.fg,
    line: self.line,
    accent: self.accent,
    muted: self.muted,
    surface: self.surface,
    border: self.border,
    font: self.font,
    transparent: self.transparent,
    padding: Some(padding),
    title: self.title,
    description: self.description,
    debug_layout: self.debug_layout,
  }
}

///|
pub fn SvgOptions::with_transparent(self : SvgOptions) -> SvgOptions {
  {
    bg: self.bg,
    fg: self.fg,
    line: self.line,
    accent: self.accent,
    muted: self.muted,
    surface: self.surface,
    border: self.border,
    font: self.font,
    transparent: Some(true),
    padding: self.padding,
    title: self.title,
    description: self.description,
    debug_layout: self.debug_layout,
  }
}

///|
pub fn SvgOptions::with_title(self : SvgOptions, title : String) -> SvgOptions {
  {
    bg: self.bg,
    fg: self.fg,
    line: self.line,
    accent: self.accent,
    muted: self.muted,
    surface: self.surface,
    border: self.border,
    font: self.font,
    transparent: self.transparent,
    padding: self.padding,
    title: Some(title),
    description: self.description,
    debug_layout: self.debug_layout,
  }
}

///|
pub fn SvgOptions::with_description(
  self : SvgOptions,
  description : String,
) -> SvgOptions {
  {
    bg: self.bg,
    fg: self.fg,
    line: self.line,
    accent: self.accent,
    muted: self.muted,
    surface: self.surface,
    border: self.border,
    font: self.font,
    transparent: self.transparent,
    padding: self.padding,
    title: self.title,
    description: Some(description),
    debug_layout: self.debug_layout,
  }
}

///|
/// Draws graph layout diagnostics in SVG output. Node, label, and edge bounds
/// are colorized; potential overlaps are highlighted in red.
pub fn SvgOptions::with_debug_layout(self : SvgOptions) -> SvgOptions {
  {
    bg: self.bg,
    fg: self.fg,
    line: self.line,
    accent: self.accent,
    muted: self.muted,
    surface: self.surface,
    border: self.border,
    font: self.font,
    transparent: self.transparent,
    padding: self.padding,
    title: self.title,
    description: self.description,
    debug_layout: Some(true),
  }
}

///|
fn svg_options_from_colors(
  colors : DiagramColors,
  font? : String = "monospace",
  transparent? : Bool = false,
  padding? : Int = 20,
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
    padding: Some(padding),
    title: None,
    description: None,
    debug_layout: Some(false),
  }
}

///|
pub fn svg_options_from_theme(
  name : String,
  font? : String = "monospace",
  transparent? : Bool = false,
  padding? : Int = 20,
) -> SvgOptions? {
  match themes.get(name) {
    Some(colors) =>
      Some(svg_options_from_colors(colors, font~, transparent~, padding~))
    None => None
  }
}
