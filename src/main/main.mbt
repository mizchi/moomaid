///|
async fn main {
  @async.sleep(16)
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
  sb.write_view(
    "<!DOCTYPE html>\n<html><head><meta charset=\"utf-8\"><title>Mermaid SVG Preview</title>\n",
  )
  sb.write_view(
    "<style>body{font-family:system-ui;background:#f8f8f8;padding:20px;max-width:1200px;margin:0 auto}\n",
  )
  sb.write_view(
    "h2{color:#333;border-bottom:2px solid #ddd;padding-bottom:8px}\n",
  )
  sb.write_view(
    ".card{background:white;border-radius:12px;padding:24px;margin:16px 0;box-shadow:0 2px 8px rgba(0,0,0,0.08)}\n",
  )
  sb.write_view(".grid{display:grid;grid-template-columns:1fr 1fr;gap:16px}\n")
  sb.write_view("@media(max-width:800px){.grid{grid-template-columns:1fr}}\n")
  sb.write_view("svg{max-width:100%;height:auto}</style></head><body>\n")
  sb.write_view("<h1>mizchi/mermaid SVG Preview</h1>\n")
  sb.write_view("<div class=\"grid\">\n")
  sb.write_view("<div class=\"card\"><h2>Flowchart TD</h2>\n")
  sb.write_view(@mermaid.render_mermaid(flow))
  sb.write_view("\n</div>\n")
  sb.write_view("<div class=\"card\"><h2>Flowchart LR</h2>\n")
  sb.write_view(@mermaid.render_mermaid(flow_lr))
  sb.write_view("\n</div>\n")
  sb.write_view("<div class=\"card\"><h2>State Diagram</h2>\n")
  sb.write_view(@mermaid.render_mermaid(state))
  sb.write_view("\n</div>\n")
  sb.write_view("<div class=\"card\"><h2>Sequence Diagram</h2>\n")
  sb.write_view(@mermaid.render_mermaid(seq))
  sb.write_view("\n</div>\n")
  sb.write_view("<div class=\"card\"><h2>Class Diagram</h2>\n")
  sb.write_view(@mermaid.render_mermaid(cls))
  sb.write_view("\n</div>\n")
  sb.write_view("</div>\n")
  sb.write_view("<h2>Dark Theme (GitHub Dark)</h2>\n")
  sb.write_view(
    "<div class=\"card\" style=\"background:#0d1117;padding:24px;border-radius:12px\">\n",
  )
  let theme = @mermaid.from_shiki_theme(@highlight.github_dark())
  let dark_options = @mermaid.render_options_from_colors(theme)
  sb.write_view(@mermaid.render_mermaid(flow, options=dark_options))
  sb.write_view("\n</div>\n")
  sb.write_view("</body></html>")
  println(sb.to_string())
}
