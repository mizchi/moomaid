///|
fn print_usage() -> Unit {
  println("moomaid - Mermaid diagram renderer for MoonBit")
  println("")
  println("Usage:")
  println("  moomaid [options] <file>")
  println("  cat diagram.mmd | just cli-stdin [options]")
  println("")
  println("Options:")
  println("  --svg          Output SVG (default: ASCII)")
  println("  --ascii        Output ASCII art")
  println("  --width <n>    Max width for ASCII (default: 80)")
  println("  --help         Show this help")
  println("")
  println("Examples:")
  println("  # Render from file")
  println("  just cli diagram.mmd")
  println("  just cli --svg diagram.mmd")
  println("")
  println("  # Render from stdin (via just)")
  println("  echo 'graph LR")
  println("    A --> B --> C' | just cli-stdin")
  println("")
  println("  # Sequence diagram from stdin")
  println("  cat <<EOF | just cli-stdin")
  println("  sequenceDiagram")
  println("    participant Client")
  println("    participant API")
  println("    participant DB")
  println("    Client->>API: Request")
  println("    API->>DB: Query")
  println("    DB-->>API: Result")
  println("    API-->>Client: Response")
  println("  EOF")
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
  let args = @env.args()
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
    } else if not(arg.has_prefix("--")) {
      file_path = Some(arg)
    }
    i = i + 1
  }
  if show_help {
    print_usage()
    return
  }
  match file_path {
    None => {
      println("Error: no input file specified")
      println("")
      print_usage()
    }
    Some(path) => {
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
  }
}
