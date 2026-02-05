///|
fn print_usage() -> Unit {
  println("Usage: mermaid-cli [options] [file]")
  println("")
  println("Render Mermaid diagrams to ASCII or SVG.")
  println("")
  println("Options:")
  println("  --svg          Output SVG (default: ASCII)")
  println("  --ascii        Output ASCII art")
  println("  --width <n>    Max width for ASCII (default: 80)")
  println("  --help         Show this help")
  println("")
  println("Examples:")
  println("  moon run src/cli --target js -- diagram.mmd")
  println("  moon run src/cli --target js -- --svg diagram.mmd")
  println("")
  println("--- Diagram Types ---")
  println("")
  println("Flowchart (graph relationships, data flow):")
  println("  graph LR")
  println("    Input --> Process --> Output")
  println("")
  println("  graph TD")
  println("    Start[Start] --> Auth{Auth}")
  println("    Auth -->|pass| Load[Load Data]")
  println("    Auth -->|fail| Error[Error Page]")
  println("    Load --> Validate{Validate}")
  println("    Validate -->|ok| Process[Process]")
  println("    Validate -->|ng| Error")
  println("    Process --> Save[Save]")
  println("    Save --> Done[Done]")
  println("    Error --> Done")
  println("")
  println("Sequence (layer boundaries, API calls):")
  println("  sequenceDiagram")
  println("    participant Browser")
  println("    participant API")
  println("    participant Auth")
  println("    participant DB")
  println("    Browser->>API: POST /login")
  println("    API->>Auth: Validate token")
  println("    Auth-->>API: OK")
  println("    API->>DB: SELECT user")
  println("    DB-->>API: User data")
  println("    API-->>Browser: 200 JSON")
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
      if svg_mode {
        println(@mermaid.render_mermaid(text))
      } else {
        let options : @mermaid.AsciiRenderOptions = {
          use_ascii: false,
          padding_x: 2,
          padding_y: 1,
          box_border_padding: 1,
          max_width: width,
        }
        println(@mermaid.render_mermaid_ascii(text, options~))
      }
    }
  }
}
