///|
/// Output format accepted by the portable skill API.
pub(all) enum OutputFormat {
  Ascii
  Svg
} derive(Debug, Eq)

///|
/// Parse the stable CLI spelling for an output format.
pub fn OutputFormat::parse(value : StringView) -> OutputFormat? {
  match value {
    "ascii" => Some(Ascii)
    "svg" => Some(Svg)
    _ => None
  }
}

///|
pub fn ParseDiagnostic::display(self : ParseDiagnostic) -> String {
  "line " +
  self.line.to_string() +
  ", column " +
  self.column.to_string() +
  ": " +
  self.message
}

///|
fn render_ascii_diagram(diagram : MermaidDiagram) -> String {
  match diagram {
    Graph(g) => render_graph_ascii(g, default_ascii_options())
    Sequence(s) => render_sequence_ascii(s, default_ascii_options())
    Timeline(t) => render_timeline_ascii(t)
    GitGraph(g) => render_git_graph_ascii(g)
    Gantt(g) => render_gantt_ascii(g)
    Outline(d) => render_outline_ascii(d)
  }
}

///|
fn render_svg_diagram(diagram : MermaidDiagram, options : SvgOptions) -> String {
  match diagram {
    Graph(g) => render_graph_svg(g, options)
    Sequence(s) => render_sequence_svg(s, options)
    Timeline(t) => render_timeline_svg(t, options)
    GitGraph(g) => render_git_graph_svg(g, options)
    Gantt(g) => render_gantt_svg(g, options)
    Outline(d) => render_outline_svg(d, options)
  }
}

///|
pub fn render_svg_checked(
  text : String,
  options? : SvgOptions = default_render_options(),
) -> Result[String, ParseDiagnostic] {
  match parse_checked(text) {
    Ok(diagram) => Ok(render_svg_diagram(diagram, options))
    Err(error) => Err(error)
  }
}

///|
pub fn render_checked(
  text : String,
  format : OutputFormat,
) -> Result[String, ParseDiagnostic] {
  match format {
    Ascii =>
      match parse_checked(text) {
        Ok(diagram) => Ok(render_ascii_diagram(diagram))
        Err(error) => Err(error)
      }
    Svg => render_svg_checked(text)
  }
}

///| Render Mermaid source using the requested portable output format.

///|

///| This is the shared contract for `.mbtx` adapters and the Mooncakes Wasm

///|
/// executable package.
pub fn render(text : String, format : OutputFormat) -> String {
  match format {
    Ascii => render_to_string(text)
    Svg => experimental_render_to_svg(text)
  }
}
