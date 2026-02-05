///|
pub struct Cell {
  mut ch : Char
} derive(Show, Eq)

///|
pub struct Canvas {
  width : Int
  height : Int
  cells : Array[Array[Cell]]
} derive(Show, Eq)

///|
pub fn Canvas::new(width : Int, height : Int) -> Canvas {
  let rows : Array[Array[Cell]] = []
  for _ in 0..<height {
    let row : Array[Cell] = []
    for _ in 0..<width {
      row.push({ ch: ' ' })
    }
    rows.push(row)
  }
  { width, height, cells: rows }
}

///|
fn Canvas::set(self : Canvas, x : Int, y : Int, ch : Char) -> Unit {
  if x < 0 || y < 0 || x >= self.width || y >= self.height {
    return
  }
  self.cells[y][x].ch = ch
}

///|
let dir_up : Int = 1

///|
let dir_down : Int = 2

///|
let dir_left : Int = 4

///|
let dir_right : Int = 8

///|
fn line_directions(ch : Char) -> Int {
  match ch {
    '─' | '-' => dir_left | dir_right
    '│' | '|' => dir_up | dir_down
    '┌' => dir_right | dir_down
    '┐' => dir_left | dir_down
    '└' => dir_right | dir_up
    '┘' => dir_left | dir_up
    '├' => dir_up | dir_down | dir_right
    '┤' => dir_up | dir_down | dir_left
    '┬' => dir_left | dir_right | dir_down
    '┴' => dir_left | dir_right | dir_up
    '┼' | '+' => dir_up | dir_down | dir_left | dir_right
    _ => 0
  }
}

///|
fn resolve_line_char(dirs : Int, use_ascii : Bool) -> Char {
  if use_ascii {
    if dirs == (dir_left | dir_right) {
      '-'
    } else if dirs == (dir_up | dir_down) {
      '|'
    } else {
      '+'
    }
  } else if dirs == (dir_left | dir_right) {
    '─'
  } else if dirs == (dir_up | dir_down) {
    '│'
  } else if dirs == (dir_right | dir_down) {
    '┌'
  } else if dirs == (dir_left | dir_down) {
    '┐'
  } else if dirs == (dir_right | dir_up) {
    '└'
  } else if dirs == (dir_left | dir_up) {
    '┘'
  } else if dirs == (dir_up | dir_down | dir_right) {
    '├'
  } else if dirs == (dir_up | dir_down | dir_left) {
    '┤'
  } else if dirs == (dir_left | dir_right | dir_down) {
    '┬'
  } else if dirs == (dir_left | dir_right | dir_up) {
    '┴'
  } else {
    '┼'
  }
}

///|
fn Canvas::set_line(
  self : Canvas,
  x : Int,
  y : Int,
  ch : Char,
  use_ascii : Bool,
) -> Unit {
  if x < 0 || y < 0 || x >= self.width || y >= self.height {
    return
  }
  let old = self.cells[y][x].ch
  let old_dirs = line_directions(old)
  let new_dirs = line_directions(ch)
  if old_dirs != 0 && new_dirs != 0 {
    self.cells[y][x].ch = resolve_line_char(old_dirs | new_dirs, use_ascii)
  } else {
    self.cells[y][x].ch = ch
  }
}

///|
fn Canvas::draw_text(self : Canvas, x : Int, y : Int, text : String) -> Unit {
  let mut cx = x
  for c in text {
    self.set(cx, y, c)
    cx += 1
  }
}

///|
fn box_chars(use_ascii : Bool) -> (Char, Char, Char, Char, Char, Char) {
  if use_ascii {
    ('+', '+', '+', '+', '-', '|')
  } else {
    ('┌', '┐', '└', '┘', '─', '│')
  }
}

///|
fn rounded_box_chars(use_ascii : Bool) -> (Char, Char, Char, Char, Char, Char) {
  if use_ascii {
    ('+', '+', '+', '+', '-', '|')
  } else {
    ('╭', '╮', '╰', '╯', '─', '│')
  }
}

///|
fn Canvas::draw_box(
  self : Canvas,
  x : Int,
  y : Int,
  w : Int,
  h : Int,
  use_ascii : Bool,
) -> Unit {
  if w <= 1 || h <= 1 {
    return
  }
  let (tl, tr, bl, br, hch, vch) = box_chars(use_ascii)
  self.set(x, y, tl)
  self.set(x + w - 1, y, tr)
  self.set(x, y + h - 1, bl)
  self.set(x + w - 1, y + h - 1, br)
  for i in (x + 1)..<(x + w - 1) {
    self.set(i, y, hch)
    self.set(i, y + h - 1, hch)
  }
  for j in (y + 1)..<(y + h - 1) {
    self.set(x, j, vch)
    self.set(x + w - 1, j, vch)
  }
}

///|
fn Canvas::draw_rounded_box(
  self : Canvas,
  x : Int,
  y : Int,
  w : Int,
  h : Int,
  use_ascii : Bool,
) -> Unit {
  if w <= 1 || h <= 1 {
    return
  }
  let (tl, tr, bl, br, hch, vch) = rounded_box_chars(use_ascii)
  self.set(x, y, tl)
  self.set(x + w - 1, y, tr)
  self.set(x, y + h - 1, bl)
  self.set(x + w - 1, y + h - 1, br)
  for i in (x + 1)..<(x + w - 1) {
    self.set(i, y, hch)
    self.set(i, y + h - 1, hch)
  }
  for j in (y + 1)..<(y + h - 1) {
    self.set(x, j, vch)
    self.set(x + w - 1, j, vch)
  }
}

///|
fn Canvas::draw_hline(
  self : Canvas,
  x1 : Int,
  x2 : Int,
  y : Int,
  use_ascii : Bool,
) -> Unit {
  let (_, _, _, _, hch, _) = box_chars(use_ascii)
  let (start, end) = if x1 <= x2 { (x1, x2) } else { (x2, x1) }
  for x in start..<=end {
    self.set(x, y, hch)
  }
}

///|
fn Canvas::draw_vline(
  self : Canvas,
  x : Int,
  y1 : Int,
  y2 : Int,
  use_ascii : Bool,
) -> Unit {
  let (_, _, _, _, _, vch) = box_chars(use_ascii)
  let (start, end) = if y1 <= y2 { (y1, y2) } else { (y2, y1) }
  for y in start..<=end {
    self.set(x, y, vch)
  }
}

///|
fn arrow_char(dx : Int, dy : Int, use_ascii : Bool) -> Char {
  if use_ascii {
    if dx > 0 {
      '>'
    } else if dx < 0 {
      '<'
    } else if dy > 0 {
      'v'
    } else {
      '^'
    }
  } else if dx > 0 {
    '▶'
  } else if dx < 0 {
    '◀'
  } else if dy > 0 {
    '▼'
  } else {
    '▲'
  }
}

///|
fn corner_char(dx : Int, dy : Int, use_ascii : Bool) -> Char {
  if use_ascii {
    '+'
  } else if dx > 0 && dy > 0 {
    '┐'
  } else if dx > 0 && dy < 0 {
    '┘'
  } else if dx < 0 && dy > 0 {
    '┌'
  } else {
    '└'
  }
}

///|
fn Canvas::draw_edge_line(
  self : Canvas,
  start : Point,
  end_ : Point,
  use_ascii : Bool,
) -> Unit {
  let (_, _, _, _, hch, vch) = box_chars(use_ascii)
  let dx = end_.x - start.x
  let dy = end_.y - start.y
  if start.y == end_.y {
    let (s, e) = if dx > 0 { (start.x, end_.x) } else { (end_.x, start.x) }
    for x in s..<=e {
      self.set_line(x, start.y, hch, use_ascii)
    }
    self.set(end_.x, end_.y, arrow_char(dx, dy, use_ascii))
  } else if start.x == end_.x {
    let (s, e) = if dy > 0 { (start.y, end_.y) } else { (end_.y, start.y) }
    for y in s..<=e {
      self.set_line(start.x, y, vch, use_ascii)
    }
    self.set(end_.x, end_.y, arrow_char(dx, dy, use_ascii))
  } else {
    // L-shaped: horizontal then vertical
    // Horizontal segment (excluding bend and start points)
    let (hs, he) = if dx > 0 {
      (start.x + 1, end_.x - 1)
    } else {
      (end_.x + 1, start.x - 1)
    }
    for x in hs..<=he {
      self.set_line(x, start.y, hch, use_ascii)
    }
    // Vertical segment (excluding bend point)
    let (vs, ve) = if dy > 0 {
      (start.y + 1, end_.y)
    } else {
      (end_.y, start.y - 1)
    }
    for y in vs..<=ve {
      self.set_line(end_.x, y, vch, use_ascii)
    }
    // Corner at bend point (merging with other edges)
    self.set_line(end_.x, start.y, corner_char(dx, dy, use_ascii), use_ascii)
    // Arrow points in last segment direction (vertical)
    self.set(end_.x, end_.y, arrow_char(0, dy, use_ascii))
  }
}

///|
fn Canvas::draw_state_marker(
  self : Canvas,
  box : LayoutBox,
  use_ascii : Bool,
  filled : Bool,
) -> Unit {
  let cx = box.x + box.width / 2
  let cy = box.y + box.height / 2
  let ch = if use_ascii {
    if filled {
      'o'
    } else {
      'O'
    }
  } else if filled {
    '●'
  } else {
    '◎'
  }
  self.set(cx, cy, ch)
}

///|
pub fn Canvas::render(self : Canvas) -> String {
  let lines : Array[String] = []
  for row in self.cells {
    let sb = StringBuilder::new()
    for cell in row {
      sb.write_char(cell.ch)
    }
    lines.push(sb.to_string().trim_end().to_string())
  }
  // Remove trailing blank lines
  while lines.length() > 0 && lines[lines.length() - 1] == "" {
    let _ = lines.pop()

  }
  lines.join("\n")
}

///|
pub fn render_graph_canvas(
  diagram : GraphDiagram,
  options : AsciiRenderOptions,
) -> Canvas {
  let layout = layout_graph(diagram, options)
  let canvas = Canvas::new(layout.width + 2, layout.height + 2)
  // Pass 1: draw all edge lines
  for edge in layout.edges {
    canvas.draw_edge_line(edge.start, edge.end, options.use_ascii)
  }
  // Pass 1.5: add start connectors for L-shaped edges
  for edge in layout.edges {
    let dx = edge.end.x - edge.start.x
    let dy = edge.end.y - edge.start.y
    if dx != 0 && dy != 0 {
      let box_dir = match layout.direction {
        Direction::TD => dir_up
        Direction::BT => dir_down
        Direction::LR => dir_left
        Direction::RL => dir_right
      }
      let h_dir = if dx > 0 { dir_right } else { dir_left }
      canvas.set_line(
        edge.start.x,
        edge.start.y,
        resolve_line_char(box_dir | h_dir, options.use_ascii),
        options.use_ascii,
      )
    }
  }
  // Pass 2: draw edge labels on top of lines
  for edge in layout.edges {
    match edge.edge.label {
      Some(label) => {
        let lx = (edge.start.x + edge.end.x) / 2
        let ly = if edge.start.x != edge.end.x && edge.start.y != edge.end.y {
          edge.start.y
        } else {
          (edge.start.y + edge.end.y) / 2 - 1
        }
        canvas.draw_text(lx, ly, label)
      }
      None => ()
    }
  }
  for node in layout.nodes {
    let b = node.box
    match node.node.shape {
      NodeShape::StateStart =>
        canvas.draw_state_marker(b, options.use_ascii, true)
      NodeShape::StateEnd =>
        canvas.draw_state_marker(b, options.use_ascii, false)
      _ => {
        let draw_fn = match node.node.shape {
          NodeShape::Rounded => Canvas::draw_rounded_box
          _ => Canvas::draw_box
        }
        draw_fn(canvas, b.x, b.y, b.width, b.height, options.use_ascii)
        let mut y = b.y + options.padding_y
        let mut section_index = 0
        for section in node.node.sections {
          for line in section {
            canvas.draw_text(b.x + options.padding_x, y, line)
            y += 1
          }
          if section_index < node.node.sections.length() - 1 {
            canvas.draw_hline(b.x + 1, b.x + b.width - 2, y, options.use_ascii)
            y += 1
          }
          section_index += 1
        }
      }
    }
  }
  canvas
}

///|
pub fn render_sequence_canvas(
  diagram : SequenceDiagram,
  options : AsciiRenderOptions,
) -> Canvas {
  let layout = layout_sequence(diagram, options)
  let canvas = Canvas::new(layout.width + 2, layout.height + 2)
  for actor in layout.actors {
    let b = actor.box
    canvas.draw_box(b.x, b.y, b.width, b.height, options.use_ascii)
    canvas.draw_text(
      b.x + options.padding_x,
      b.y + options.padding_y,
      actor.actor.label,
    )
    let cx = b.x + b.width / 2
    canvas.draw_vline(cx, b.y + b.height, layout.height - 1, options.use_ascii)
  }
  for msg in layout.messages {
    let dx = msg.end.x - msg.start.x
    canvas.draw_hline(msg.start.x, msg.end.x, msg.y, options.use_ascii)
    canvas.set(msg.end.x, msg.end.y, arrow_char(dx, 0, options.use_ascii))
    if msg.message.text.length() > 0 {
      canvas.draw_text(msg.start.x + 1, msg.y - 1, msg.message.text)
    }
  }
  canvas
}

///|
pub fn render_graph_ascii(
  diagram : GraphDiagram,
  options : AsciiRenderOptions,
) -> String {
  render_graph_canvas(diagram, options).render()
}

///|
pub fn render_sequence_ascii(
  diagram : SequenceDiagram,
  options : AsciiRenderOptions,
) -> String {
  render_sequence_canvas(diagram, options).render()
}
