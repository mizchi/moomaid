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
  println("  --width <n>    Max width for ASCII (default: 80)")
  println("  -              Read from stdin")
  println("  --help         Show this help")
  println("")
  println("Examples:")
  println("  # Build and run with node")
  println("  moon build src/cli --target js")
  println("  node _build/js/release/build/cli/cli.js diagram.mmd")
  println("")
  println("  # Pipe from stdin")
  println(
    "  echo 'graph LR; A --> B' | node _build/js/release/build/cli/cli.js -",
  )
  println("")
  println("  # SVG output")
  println("  node _build/js/release/build/cli/cli.js --svg diagram.mmd")
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
fn render(text : String, svg_mode : Bool, width : Int) -> Unit {
  if svg_mode {
    println(@moomaid.experimental_render_to_svg(text))
  } else {
    let options : @moomaid.Options = {
      use_ascii: false,
      padding_x: 2,
      padding_y: 1,
      box_border_padding: 1,
      max_width: width,
    }
    println(@moomaid.render_to_string(text, options~))
  }
}

///|
fn main {
  let raw_args = @env.args()
  // Skip node path and script path (process.argv[0], [1])
  let args : Array[String] = []
  for i = 2; i < raw_args.length(); i = i + 1 {
    args.push(raw_args[i])
  }
  let mut file_path : String? = None
  let mut svg_mode = false
  let mut width = 80
  let mut show_help = false
  let mut i = 0
  while i < args.length() {
    let arg = args[i]
    if arg == "--help" || arg == "-h" {
      show_help = true
    } else if arg == "--svg" {
      svg_mode = true
    } else if arg == "--ascii" {
      svg_mode = false
    } else if arg == "--width" {
      i = i + 1
      if i < args.length() {
        width = @strconv.parse_int(args[i]) catch { _ => 80 }
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
  render(text, svg_mode, width)
}
