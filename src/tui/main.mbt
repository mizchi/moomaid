///|
using @vnode {type VNodeApp}

///|
let esc : String = "\u001b["

///|
struct DiagramEntry {
  label : String
  lines : Array[String]
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
fn build_diagrams() -> Array[DiagramEntry] {
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
  let sources = [
    ("Flow TD", flow_td),
    ("Flow LR", flow_lr),
    ("State", state),
    ("Sequence", seq),
    ("Class", cls),
  ]
  let entries : Array[DiagramEntry] = []
  for item in sources {
    let rendered = @mermaid.render_mermaid_ascii(item.1)
    let lines = split_lines(rendered)
    entries.push({ label: item.0, lines })
  }
  entries
}

///|
async fn main {
  let (_width, height) = @tui.get_terminal_size()
  let diagrams = build_diagrams()

  let active_tab = @signals.signal(0)
  let scroll_offset = @signals.signal(0)

  @tui.print_raw(VNodeApp::init_terminal())
  @tui.enable_raw_mode()

  fn do_render() {
    let tab_idx = active_tab.get()
    let offset = scroll_offset.get()
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
    sb.write_string(esc + "K\r\n")

    // Content
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
    sb.write_string("Tab: switch | ↑↓: scroll | q: quit")
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
          }
          @tui.KeyEvent::Special(@tui.SpecialKey::BackTab, _) => {
            let cur = active_tab.get()
            let prev = if cur == 0 { diagrams.length() - 1 } else { cur - 1 }
            active_tab.set(prev)
            scroll_offset.set(0)
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
