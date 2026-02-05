///|
using @vnode {type VNodeApp}

///|
let esc : String = "\u001b["

///|
struct DiagramEntry {
  label : String
  lines : Array[String]
  svg_commands : Array[String]
}

///|
fn split_lines(s : String) -> Array[String] {
  let out : Array[String] = []
  for part in s.split("\n") {
    out.push(part.to_string())
  }
  out
}

///|
fn build_diagrams(width : Int) -> Array[DiagramEntry] {
  let options : @mermaid.AsciiRenderOptions = {
    use_ascii: false,
    padding_x: 2,
    padding_y: 1,
    box_border_padding: 1,
    max_width: width,
  }
  let flow_td =
    #|graph TD
    #|  A[Start] --> B(Decision)
    #|  B -->|yes| C[Success]
    #|  B -->|no| D[Retry]
    #|  D --> B
    #|
  let flow_lr =
    #|graph LR
    #|  Input --> Process --> Output
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
  let flow_complex =
    #|graph TD
    #|  Start[Start] --> Auth{Auth}
    #|  Auth -->|pass| Load[Load Data]
    #|  Auth -->|fail| Error[Error Page]
    #|  Load --> Validate{Validate}
    #|  Validate -->|ok| Process[Process]
    #|  Validate -->|ng| Error
    #|  Process --> Save[Save]
    #|  Save --> Done[Done]
    #|  Error --> Done
    #|
  let seq_complex =
    #|sequenceDiagram
    #|  participant Browser
    #|  participant API
    #|  participant Auth
    #|  participant DB
    #|  Browser->>API: POST /login
    #|  API->>Auth: Validate token
    #|  Auth-->>API: OK
    #|  API->>DB: SELECT user
    #|  DB-->>API: User data
    #|  API-->>Browser: 200 JSON
    #|
  let sources = [
    ("Flow TD", flow_td),
    ("Flow LR", flow_lr),
    ("State", state),
    ("Sequence", seq),
    ("Class", cls),
    ("Flow Complex", flow_complex),
    ("Seq Complex", seq_complex),
  ]
  let px_width = width * 8
  let px_height = px_width * 3 / 4
  let entries : Array[DiagramEntry] = []
  let mut image_id = 1
  for item in sources {
    let rendered = @mermaid.render_mermaid_ascii(item.1, options~)
    let lines = split_lines(rendered)
    let svg_str = @mermaid.render_mermaid(item.1)
    let svg_commands = match
      render_svg_to_kitty_commands(svg_str, px_width, px_height, image_id) {
      Some(cmds) => cmds
      None => []
    }
    image_id = image_id + 1
    entries.push({ label: item.0, lines, svg_commands })
  }
  entries
}

///|
async fn main {
  let (width, height) = @tui.get_terminal_size()
  let diagrams = build_diagrams(width)
  let active_tab = @signals.signal(0)
  let scroll_offset = @signals.signal(0)
  let svg_mode = @signals.signal(false)
  @tui.print_raw(VNodeApp::init_terminal())
  @tui.enable_raw_mode()
  fn do_render() {
    let tab_idx = active_tab.get()
    let offset = scroll_offset.get()
    let is_svg = svg_mode.get()
    let diagram = diagrams[tab_idx]
    let lines = diagram.lines
    let sb = StringBuilder::new()
    sb.write_string(esc + "H")

    // Tab bar
    for i, d in diagrams {
      if i == tab_idx {
        sb.write_string(esc + "30;46m")
      } else {
        sb.write_string(esc + "37;48;5;238m")
      }
      sb.write_string(" ")
      sb.write_string(d.label)
      sb.write_string(" " + esc + "0m ")
    }
    let mode_label = if is_svg { "[SVG]" } else { "[ASCII]" }
    sb.write_string(esc + "33m " + mode_label + esc + "0m")
    sb.write_string(esc + "K\r\n")
    if is_svg && diagram.svg_commands.length() > 0 {
      // SVG mode: clear content area then output Kitty commands
      let content_h = height - 2
      for i in 0..<content_h {
        ignore(i)
        sb.write_string(esc + "K\r\n")
      }
      // Footer
      sb.write_string(esc + "38;5;242m")
      sb.write_string("Tab: switch | s: ascii/svg | q: quit")
      sb.write_string(esc + "K" + esc + "0m")
      // Move cursor to content start and output image
      sb.write_string(esc + "2;1H")
      for cmd in diagram.svg_commands {
        sb.write_string(cmd)
      }
      @tui.print_raw(sb.to_string())
    } else {
      // ASCII mode
      let content_h = height - 2
      let max_off = if lines.length() > content_h {
        lines.length() - content_h
      } else {
        0
      }
      let off = if offset > max_off { max_off } else { offset }
      if off != offset {
        scroll_offset.set(off)
      }
      for i in 0..<content_h {
        let li = off + i
        if li < lines.length() {
          sb.write_string(lines[li])
        }
        sb.write_string(esc + "K\r\n")
      }

      // Footer
      let end_line = if off + content_h > lines.length() {
        lines.length()
      } else {
        off + content_h
      }
      sb.write_string(esc + "38;5;242m")
      sb.write_string("Tab: switch | ↑↓: scroll | s: ascii/svg | q: quit")
      if lines.length() > content_h {
        sb.write_string(
          " | Ln " +
          (off + 1).to_string() +
          "-" +
          end_line.to_string() +
          "/" +
          lines.length().to_string(),
        )
      }
      sb.write_string(esc + "K" + esc + "0m")
      @tui.print_raw(sb.to_string())
    }
  }

  do_render()
  let mut running = true
  while running {
    let key = @tui.read_key()
    if key.length() == 0 {
      continue
    }
    let event = @tui.parse_input(key)
    let mut need_render = true
    match event {
      @tui.InputEvent::Key(key_event) =>
        match key_event {
          @tui.KeyEvent::Char('q', @tui.KeyModifier::None) => running = false
          @tui.KeyEvent::Char('c', @tui.KeyModifier::Ctrl) => running = false
          @tui.KeyEvent::Special(@tui.SpecialKey::Escape, _) => running = false
          @tui.KeyEvent::Special(@tui.SpecialKey::Tab, @tui.KeyModifier::None) => {
            let cur = active_tab.get()
            let next = if cur + 1 >= diagrams.length() { 0 } else { cur + 1 }
            active_tab.set(next)
            scroll_offset.set(0)
            if svg_mode.get() {
              @tui.print_raw(kitty_delete_all_visible())
            }
          }
          @tui.KeyEvent::Special(@tui.SpecialKey::BackTab, _) => {
            let cur = active_tab.get()
            let prev = if cur == 0 { diagrams.length() - 1 } else { cur - 1 }
            active_tab.set(prev)
            scroll_offset.set(0)
            if svg_mode.get() {
              @tui.print_raw(kitty_delete_all_visible())
            }
          }
          @tui.KeyEvent::Special(@tui.SpecialKey::Up, _) => {
            let cur = scroll_offset.get()
            if cur > 0 {
              scroll_offset.set(cur - 1)
            }
          }
          @tui.KeyEvent::Special(@tui.SpecialKey::Down, _) => {
            let cur = scroll_offset.get()
            scroll_offset.set(cur + 1)
          }
          @tui.KeyEvent::Char('s', @tui.KeyModifier::None) => {
            let entering_ascii = svg_mode.get()
            svg_mode.set(not(entering_ascii))
            // Clear screen and kitty images when switching modes
            @tui.print_raw(kitty_delete_all_visible() + esc + "2J")
          }
          _ => need_render = false
        }
      _ => need_render = false
    }
    if need_render && running {
      do_render()
    }
  }
  @tui.cleanup_stdin()
  @tui.print_raw(VNodeApp::restore_terminal())
}
