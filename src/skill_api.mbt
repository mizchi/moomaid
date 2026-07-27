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
