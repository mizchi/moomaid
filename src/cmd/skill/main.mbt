///|
struct SkillOptions {
  format : @mermaid.OutputFormat
  theme : String?
  font : String?
  padding : Int?
  background : String?
  transparent : Bool
  debug_layout : Bool
  title : String?
  description : String?
}

///|
fn usage() -> String {
  "Usage: moomaid-skill [--format ascii|svg] [--theme NAME] [--font NAME] [--padding PX] [--background COLOR] [--transparent] [--debug-layout] [--title TEXT] [--description TEXT] < Mermaid.mmd"
}

///|
fn parse_options(args : Array[String]) -> Result[SkillOptions, String] {
  let mut format = @mermaid.OutputFormat::Ascii
  let mut theme : String? = None
  let mut font : String? = None
  let mut padding : Int? = None
  let mut background : String? = None
  let mut transparent = false
  let mut debug_layout = false
  let mut title : String? = None
  let mut description : String? = None
  let mut i = 1
  while i < args.length() {
    let arg = args[i]
    if arg == "--transparent" {
      transparent = true
      i += 1
      continue
    }
    if arg == "--debug-layout" {
      debug_layout = true
      i += 1
      continue
    }
    let needs_value = arg == "--format" ||
      arg == "--theme" ||
      arg == "--font" ||
      arg == "--padding" ||
      arg == "--background" ||
      arg == "--title" ||
      arg == "--description"
    if !needs_value {
      return Err("unsupported option: " + arg)
    }
    i += 1
    if i >= args.length() {
      return Err(arg + " requires a value")
    }
    let value = args[i]
    if arg == "--format" {
      match @mermaid.OutputFormat::parse(value) {
        Some(parsed) => format = parsed
        None => return Err("--format must be ascii or svg")
      }
    } else if arg == "--theme" {
      theme = Some(value)
    } else if arg == "--font" {
      font = Some(value)
    } else if arg == "--padding" {
      let parsed = @string.parse_int(value) catch { _ => -1 }
      if parsed <= 0 {
        return Err("--padding must be a positive integer")
      }
      padding = Some(parsed)
    } else if arg == "--background" {
      background = Some(value)
    } else if arg == "--title" {
      title = Some(value)
    } else {
      description = Some(value)
    }
    i += 1
  }
  let has_svg_options = theme is Some(_) ||
    font is Some(_) ||
    padding is Some(_) ||
    background is Some(_) ||
    transparent ||
    debug_layout ||
    title is Some(_) ||
    description is Some(_)
  if format == @mermaid.OutputFormat::Ascii && has_svg_options {
    return Err("SVG presentation options require --format svg")
  }
  Ok({
    format,
    theme,
    font,
    padding,
    background,
    transparent,
    debug_layout,
    title,
    description,
  })
}

///|
fn svg_options_for(
  options : SkillOptions,
) -> Result[@mermaid.SvgOptions, String] {
  let mut svg_options = match options.theme {
    Some(theme) =>
      match @mermaid.svg_options_from_theme(theme) {
        Some(value) => value
        None => return Err("unknown SVG theme: " + theme)
      }
    None => @mermaid.default_svg_options()
  }
  match options.font {
    Some(font) => svg_options = svg_options.with_font(font)
    None => ()
  }
  match options.padding {
    Some(padding) => svg_options = svg_options.with_padding(padding)
    None => ()
  }
  match options.background {
    Some(background) => svg_options = svg_options.with_background(background)
    None => ()
  }
  if options.transparent {
    svg_options = svg_options.with_transparent()
  }
  if options.debug_layout {
    svg_options = svg_options.with_debug_layout()
  }
  match options.title {
    Some(title) => svg_options = svg_options.with_title(title)
    None => ()
  }
  match options.description {
    Some(description) => svg_options = svg_options.with_description(description)
    None => ()
  }
  Ok(svg_options)
}

///|
fn write_error(message : String, exit_code : Int) -> Unit {
  @fs.write_string_to_file("/dev/stderr", "moomaid: " + message + "\n") catch {
    _ => ()
  }
  @sys.exit(exit_code)
}

///|
/// Read Mermaid source from standard input and write one rendered artifact.
fn main {
  match parse_options(@env.args()) {
    Err(message) => write_error(message + "\n" + usage(), 2)
    Ok(options) => {
      let source = @fs.read_file_to_string("/dev/stdin") catch {
        @fs.IOError(message) => {
          write_error("unable to read standard input: " + message, 1)
          return
        }
      }
      let output = match options.format {
        @mermaid.OutputFormat::Ascii =>
          @mermaid.render_checked(source, @mermaid.OutputFormat::Ascii)
        @mermaid.OutputFormat::Svg =>
          match svg_options_for(options) {
            Ok(svg_options) =>
              @mermaid.render_svg_checked(source, options=svg_options)
            Err(message) => {
              write_error(message, 1)
              return
            }
          }
      }
      match output {
        Ok(artifact) => println(artifact)
        Err(diagnostic) => write_error(diagnostic.display(), 1)
      }
    }
  }
}
