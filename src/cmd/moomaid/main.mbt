///|
fn print_usage() -> Unit {
  println("moomaid - Mermaid diagram renderer for MoonBit")
  println("")
  println("Usage:")
  println("  moomaid [options] <file>")
  println("  moomaid [options] -          # read from stdin")
  println("")
  println("Options:")
  println("  --svg          Output SVG (default: ASCII)")
  println("  --ascii        Output ASCII art")
  println("  --kitty        Output Kitty graphics protocol")
  println("  --html         Output HTML with embedded SVG")
  println("  --width <n>    Max width for ASCII (default: 80)")
  println("                 For kitty: image width in px (default: 640)")
  println("  -              Read from stdin")
  println("  --help         Show this help")
  println("")
  println("Examples:")
  println("  # Build and run with node")
  println("  moon build src/cmd/moomaid --target js")
  println("  node _build/js/release/build/cmd/moomaid/moomaid.js diagram.mmd")
  println("")
  println("  # Pipe from stdin")
  println(
    "  echo 'graph LR; A --> B' | node _build/js/release/build/cmd/moomaid/moomaid.js -",
  )
  println("")
  println("  # SVG output")
  println(
    "  node _build/js/release/build/cmd/moomaid/moomaid.js --svg diagram.mmd",
  )
  println("")
  println("  # HTML output (demo page)")
  println(
    "  node _build/js/release/build/cmd/moomaid/moomaid.js --html > demo.html",
  )
  println("")
  println("  # Via just")
  println("  just cli diagram.mmd")
  println("  just cli-stdin < diagram.mmd")
  println("")
  println("--- Diagram Types ---")
  println("")
  println("graph LR / graph TD  : Flowchart (data flow, dependencies)")
  println("sequenceDiagram      : Sequence  (layer boundaries, API calls)")
  println("stateDiagram-v2      : State machine")
  println("classDiagram         : Class diagram")
}

///|
enum OutputMode {
  Ascii
  Svg
  Kitty
  Html
}

///|
let font_paths : Array[String] = [
  "/System/Library/Fonts/SFNSMono.ttf", "/System/Library/Fonts/Geneva.ttf", "/System/Library/Fonts/Helvetica.ttc",
  "/System/Library/Fonts/Supplemental/Arial.ttf", "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
  "/usr/share/fonts/TTF/DejaVuSans.ttf",
]

///|
fn detect_font() -> @font.TTFont? {
  for path in font_paths {
    let bytes = @fs.read_file_to_bytes(path) catch { _ => continue }
    // Try single font first, then font collection
    match @font.parse_font(bytes) {
      Some(font) => return Some(font)
      None =>
        match @font.parse_font_collection(bytes) {
          Some(fonts) => if fonts.length() > 0 { return Some(fonts[0]) }
          None => continue
        }
    }
  }
  None
}

///|
fn make_font_callback(
  font : @font.TTFont,
) -> (Int, Double) -> (Array[@svg.PathCommand], Double) {
  fn(codepoint : Int, font_size : Double) -> (Array[@svg.PathCommand], Double) {
    let outline = font.scaled_outline(codepoint, font_size)
    let gid = font.glyph_index(codepoint)
    let metrics = font.glyph_metrics(gid)
    let advance = metrics.advance_width.to_double() *
      font_size /
      font.units_per_em.to_double()
    (outline, advance)
  }
}

///|
fn render(text : String, mode : OutputMode, width : Int) -> Unit {
  match mode {
    Svg => println(@mermaid.experimental_render_to_svg(text))
    Html => render_html_single(text)
    Kitty => {
      let svg_str = @mermaid.experimental_render_to_svg(text)
      let height = width * 3 / 4
      let commands = match detect_font() {
        Some(font) => {
          let cb = make_font_callback(font)
          @kitty.render_svg_to_kitty_commands(
            svg_str,
            width,
            height,
            1,
            font_callback=cb,
          )
        }
        None => @kitty.render_svg_to_kitty_commands(svg_str, width, height, 1)
      }
      match commands {
        Some(cmds) => {
          let sb = StringBuilder::new()
          for cmd in cmds {
            sb.write_string(cmd)
          }
          println(sb.to_string())
        }
        None => println("Error: failed to render SVG to kitty image")
      }
    }
    Ascii => {
      let options : @mermaid.Options = {
        use_ascii: false,
        padding_x: 2,
        padding_y: 1,
        box_border_padding: 1,
        max_width: width,
      }
      println(@mermaid.render_to_string(text, options~))
    }
  }
}

///|
fn render_html_single(text : String) -> Unit {
  let sb = StringBuilder::new()
  sb.write_string(
    "<!DOCTYPE html>\n<html><head><meta charset=\"utf-8\"><title>Moomaid</title>\n",
  )
  sb.write_string(
    "<style>body{font-family:system-ui;background:#f8f8f8;padding:20px;max-width:1200px;margin:0 auto}\n",
  )
  sb.write_string(
    ".card{background:white;border-radius:12px;padding:24px;margin:16px 0;box-shadow:0 2px 8px rgba(0,0,0,0.08)}\n",
  )
  sb.write_string("svg{max-width:100%;height:auto}</style></head><body>\n")
  sb.write_string("<div class=\"card\">\n")
  sb.write_string(@mermaid.experimental_render_to_svg(text))
  sb.write_string("\n</div>\n")
  sb.write_string("</body></html>")
  println(sb.to_string())
}

///|
fn render_html_demo() -> Unit {
  let flow =
    #|graph TD
    #|  A[Start] --> B(Decision)
    #|  B -->|yes| C[Success]
    #|  B -->|no| D[Retry]
    #|  D --> B
    #|
  let state =
    #|stateDiagram-v2
    #|  [*] --> Idle
    #|  Idle --> Running
    #|  Running --> Idle
    #|  Running --> [*]
    #|
  let seq =
    #|sequenceDiagram
    #|  participant Client
    #|  participant Server
    #|  participant DB
    #|  Client->>Server: Request
    #|  Server->>DB: Query
    #|  DB-->>Server: Result
    #|  Server-->>Client: Response
    #|
  let cls =
    #|classDiagram
    #|  class Animal
    #|  Animal : +String name
    #|  Animal : +int age
    #|  Animal : +eat()
    #|  Animal : +sleep()
    #|
  let flow_lr =
    #|graph LR
    #|  Input --> Process --> Output
    #|
  let sb = StringBuilder::new()
  sb.write_string(
    "<!DOCTYPE html>\n<html><head><meta charset=\"utf-8\"><title>Mermaid SVG Preview</title>\n",
  )
  sb.write_string(
    "<style>body{font-family:system-ui;background:#f8f8f8;padding:20px;max-width:1200px;margin:0 auto}\n",
  )
  sb.write_string(
    "h2{color:#333;border-bottom:2px solid #ddd;padding-bottom:8px}\n",
  )
  sb.write_string(
    ".card{background:white;border-radius:12px;padding:24px;margin:16px 0;box-shadow:0 2px 8px rgba(0,0,0,0.08)}\n",
  )
  sb.write_string(
    ".grid{display:grid;grid-template-columns:1fr 1fr;gap:16px}\n",
  )
  sb.write_string("@media(max-width:800px){.grid{grid-template-columns:1fr}}\n")
  sb.write_string("svg{max-width:100%;height:auto}</style></head><body>\n")
  sb.write_string("<h1>mizchi/moomaid SVG Preview</h1>\n")
  sb.write_string("<div class=\"grid\">\n")
  sb.write_string("<div class=\"card\"><h2>Flowchart TD</h2>\n")
  sb.write_string(@mermaid.experimental_render_to_svg(flow))
  sb.write_string("\n</div>\n")
  sb.write_string("<div class=\"card\"><h2>Flowchart LR</h2>\n")
  sb.write_string(@mermaid.experimental_render_to_svg(flow_lr))
  sb.write_string("\n</div>\n")
  sb.write_string("<div class=\"card\"><h2>State Diagram</h2>\n")
  sb.write_string(@mermaid.experimental_render_to_svg(state))
  sb.write_string("\n</div>\n")
  sb.write_string("<div class=\"card\"><h2>Sequence Diagram</h2>\n")
  sb.write_string(@mermaid.experimental_render_to_svg(seq))
  sb.write_string("\n</div>\n")
  sb.write_string("<div class=\"card\"><h2>Class Diagram</h2>\n")
  sb.write_string(@mermaid.experimental_render_to_svg(cls))
  sb.write_string("\n</div>\n")
  sb.write_string("</div>\n")
  sb.write_string("<h2>Dark Theme (GitHub Dark)</h2>\n")
  sb.write_string(
    "<div class=\"card\" style=\"background:#0d1117;padding:24px;border-radius:12px\">\n",
  )
  let dark_options = @mermaid.svg_options_from_theme("github-dark")
  match dark_options {
    Some(opts) =>
      sb.write_string(@mermaid.experimental_render_to_svg(flow, options=opts))
    None => ()
  }
  sb.write_string("\n</div>\n")
  sb.write_string("</body></html>")
  println(sb.to_string())
}

///|
fn main {
  let raw_args = @env.args()
  // JS: process.argv = [node, script.js, ...user_args] → skip 2
  // Native: argv = [binary, ...user_args] → skip 1
  let skip = if raw_args.length() >= 2 &&
    (raw_args[1].has_suffix(".js") || raw_args[1].has_suffix(".mjs")) {
    2
  } else {
    1
  }
  let args : Array[String] = []
  for i = skip; i < raw_args.length(); i = i + 1 {
    args.push(raw_args[i])
  }
  let mut file_path : String? = None
  let mut mode : OutputMode = Ascii
  let mut width = 80
  let mut width_specified = false
  let mut show_help = false
  let mut i = 0
  while i < args.length() {
    let arg = args[i]
    if arg == "--help" || arg == "-h" {
      show_help = true
    } else if arg == "--svg" {
      mode = Svg
    } else if arg == "--ascii" {
      mode = Ascii
    } else if arg == "--kitty" {
      mode = Kitty
    } else if arg == "--html" {
      mode = Html
    } else if arg == "--width" {
      i = i + 1
      if i < args.length() {
        width = @strconv.parse_int(args[i]) catch { _ => 80 }
        width_specified = true
      }
    } else if arg == "-" {
      file_path = Some("/dev/stdin")
    } else if not(arg.has_prefix("--")) {
      file_path = Some(arg)
    }
    i = i + 1
  }
  if show_help {
    print_usage()
    return
  }
  // --html without file: render demo page
  match (mode, file_path) {
    (Html, None) => {
      render_html_demo()
      return
    }
    _ => ()
  }
  let path = match file_path {
    Some(p) => p
    None => {
      println("Error: no input file specified (use - for stdin)")
      println("")
      print_usage()
      return
    }
  }
  let text = @fs.read_file_to_string(path) catch {
    err => {
      println("Error: " + err.to_string())
      return
    }
  }
  if text.is_empty() {
    println("Error: empty input")
    println("")
    print_usage()
    return
  }
  // Default width for kitty mode is 640px
  match mode {
    Kitty => if not(width_specified) { width = 640 }
    _ => ()
  }
  render(text, mode, width)
}
