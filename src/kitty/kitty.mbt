///|
let apc : String = "\u001b_G"

///|
let st : String = "\u001b\\"

///|
fn kitty_command(params : String, payload? : String = "") -> String {
  apc + params + ";" + payload + st
}

///|
fn split_payload(payload : String, chunk_size? : Int = 4096) -> Array[String] {
  let chunks : Array[String] = []
  let len = payload.length()
  let mut i = 0
  while i < len {
    let end = if i + chunk_size > len { len } else { i + chunk_size }
    let sb = StringBuilder::new(size_hint=end - i)
    for j in i..<end {
      sb.write_char(payload[j].to_int().unsafe_to_char())
    }
    chunks.push(sb.to_string())
    i = end
  }
  chunks
}

///|
fn kitty_transmit_rgb(
  id : Int,
  width : Int,
  height : Int,
  payload : String,
  chunk_size? : Int = 4096,
) -> Array[String] {
  let chunks = split_payload(payload, chunk_size~)
  let commands : Array[String] = []
  if chunks.length() <= 1 {
    let data = if chunks.length() == 1 { chunks[0] } else { "" }
    let params = "a=T,f=24,s=" +
      width.to_string() +
      ",v=" +
      height.to_string() +
      ",i=" +
      id.to_string() +
      ",m=0"
    commands.push(kitty_command(params, payload=data))
  } else {
    for idx, chunk in chunks {
      let is_last = idx == chunks.length() - 1
      let m = if is_last { "0" } else { "1" }
      if idx == 0 {
        let params = "a=T,f=24,s=" +
          width.to_string() +
          ",v=" +
          height.to_string() +
          ",i=" +
          id.to_string() +
          ",m=" +
          m
        commands.push(kitty_command(params, payload=chunk))
      } else {
        let params = "i=" + id.to_string() + ",m=" + m
        commands.push(kitty_command(params, payload=chunk))
      }
    }
  }
  commands
}

///|
pub fn kitty_delete_all_visible() -> String {
  "\u001b_Ga=d,d=a\u001b\\"
}

///|
/// Convert SVG PathCommands to SVG path data string
fn commands_to_path_d(cmds : Array[@svg.PathCommand]) -> String {
  let sb = StringBuilder::new()
  for cmd in cmds {
    if sb.to_string().length() > 0 {
      sb.write_char(' ')
    }
    match cmd {
      @svg.MoveTo(x, y) => {
        sb.write_char('M')
        sb.write_string(x.to_string())
        sb.write_char(' ')
        sb.write_string(y.to_string())
      }
      @svg.LineTo(x, y) => {
        sb.write_char('L')
        sb.write_string(x.to_string())
        sb.write_char(' ')
        sb.write_string(y.to_string())
      }
      @svg.QuadraticCurveTo(cx, cy, x, y) => {
        sb.write_char('Q')
        sb.write_string(cx.to_string())
        sb.write_char(' ')
        sb.write_string(cy.to_string())
        sb.write_char(' ')
        sb.write_string(x.to_string())
        sb.write_char(' ')
        sb.write_string(y.to_string())
      }
      @svg.CurveTo(cx1, cy1, cx2, cy2, x, y) => {
        sb.write_char('C')
        sb.write_string(cx1.to_string())
        sb.write_char(' ')
        sb.write_string(cy1.to_string())
        sb.write_char(' ')
        sb.write_string(cx2.to_string())
        sb.write_char(' ')
        sb.write_string(cy2.to_string())
        sb.write_char(' ')
        sb.write_string(x.to_string())
        sb.write_char(' ')
        sb.write_string(y.to_string())
      }
      @svg.ClosePath => sb.write_char('Z')
      _ => ()
    }
  }
  sb.to_string()
}

///|
/// Parse a float from a string, returning 0.0 on failure
fn parse_float(s : String) -> Double {
  let mut result = 0.0
  let mut frac = 0.0
  let mut frac_div = 1.0
  let mut in_frac = false
  let mut negative = false
  for i in 0..<s.length() {
    let c = s[i].to_int().unsafe_to_char()
    if c == '-' && i == 0 {
      negative = true
    } else if c == '.' {
      in_frac = true
    } else if c >= '0' && c <= '9' {
      let digit = c.to_int() - '0'.to_int()
      if in_frac {
        frac_div = frac_div * 10.0
        frac = frac + digit.to_double() / frac_div
      } else {
        result = result * 10.0 + digit.to_double()
      }
    }
  }
  let v = result + frac
  if negative {
    -v
  } else {
    v
  }
}

///|
/// Extract attribute value from a tag string like `<text x="10" y="20" ...>`
fn extract_attr(tag : String, attr_name : String) -> String {
  let search = attr_name + "=\""
  let mut i = 0
  while i < tag.length() - search.length() {
    let mut found = true
    for j in 0..<search.length() {
      if tag[i + j] != search[j] {
        found = false
        break
      }
    }
    if found {
      let start = i + search.length()
      let mut end = start
      while end < tag.length() && tag[end].to_int().unsafe_to_char() != '"' {
        end = end + 1
      }
      let sb = StringBuilder::new()
      for k in start..<end {
        sb.write_char(tag[k].to_int().unsafe_to_char())
      }
      return sb.to_string()
    }
    i = i + 1
  }
  ""
}

///|
/// Replace <text> elements in SVG with <path> using font callback
fn replace_text_with_paths(
  svg_str : String,
  font_cb : (Int, Double) -> (Array[@svg.PathCommand], Double),
) -> String {
  let result = StringBuilder::new()
  let len = svg_str.length()
  let mut i = 0
  while i < len {
    // Look for <text
    if i + 5 < len &&
      svg_str[i].to_int().unsafe_to_char() == '<' &&
      svg_str[i + 1].to_int().unsafe_to_char() == 't' &&
      svg_str[i + 2].to_int().unsafe_to_char() == 'e' &&
      svg_str[i + 3].to_int().unsafe_to_char() == 'x' &&
      svg_str[i + 4].to_int().unsafe_to_char() == 't' &&
      (
        svg_str[i + 5].to_int().unsafe_to_char() == ' ' ||
        svg_str[i + 5].to_int().unsafe_to_char() == '>'
      ) {
      // Found <text, collect the full tag
      let tag_start = i
      let mut j = i
      // Find the end of the opening tag '>'
      while j < len && svg_str[j].to_int().unsafe_to_char() != '>' {
        j = j + 1
      }
      if j >= len {
        result.write_char(svg_str[i].to_int().unsafe_to_char())
        i = i + 1
        continue
      }
      j = j + 1 // skip '>'
      // Extract tag attributes
      let tag_sb = StringBuilder::new()
      for k in tag_start..<j {
        tag_sb.write_char(svg_str[k].to_int().unsafe_to_char())
      }
      let tag_str = tag_sb.to_string()
      // Extract text content until </text>
      let content_start = j
      let mut content_end = j
      while content_end + 6 < len {
        if svg_str[content_end].to_int().unsafe_to_char() == '<' &&
          svg_str[content_end + 1].to_int().unsafe_to_char() == '/' &&
          svg_str[content_end + 2].to_int().unsafe_to_char() == 't' &&
          svg_str[content_end + 3].to_int().unsafe_to_char() == 'e' &&
          svg_str[content_end + 4].to_int().unsafe_to_char() == 'x' &&
          svg_str[content_end + 5].to_int().unsafe_to_char() == 't' {
          break
        }
        content_end = content_end + 1
      }
      let text_sb = StringBuilder::new()
      for k in content_start..<content_end {
        text_sb.write_char(svg_str[k].to_int().unsafe_to_char())
      }
      let text_content = text_sb.to_string()
      // Skip past </text>
      let mut end_pos = content_end
      while end_pos < len && svg_str[end_pos].to_int().unsafe_to_char() != '>' {
        end_pos = end_pos + 1
      }
      end_pos = end_pos + 1 // skip '>'
      // Extract attributes
      let x = parse_float(extract_attr(tag_str, "x"))
      let y = parse_float(extract_attr(tag_str, "y"))
      let font_size_str = extract_attr(tag_str, "font-size")
      let font_size = if font_size_str.length() > 0 {
        parse_float(font_size_str)
      } else {
        14.0
      }
      let fill = extract_attr(tag_str, "fill")
      let fill_attr = if fill.length() > 0 {
        " fill=\"" + fill + "\""
      } else {
        ""
      }
      // Render text as path using font callback
      let path_d = StringBuilder::new()
      let mut cursor_x = x
      for k in 0..<text_content.length() {
        let codepoint = text_content[k].to_int()
        let (cmds, advance) = font_cb(codepoint, font_size)
        // Translate commands to cursor position
        let translated : Array[@svg.PathCommand] = []
        for cmd in cmds {
          match cmd {
            @svg.MoveTo(cx, cy) =>
              translated.push(@svg.MoveTo(cx + cursor_x, cy + y))
            @svg.LineTo(cx, cy) =>
              translated.push(@svg.LineTo(cx + cursor_x, cy + y))
            @svg.QuadraticCurveTo(cx1, cy1, cx2, cy2) =>
              translated.push(
                @svg.QuadraticCurveTo(
                  cx1 + cursor_x,
                  cy1 + y,
                  cx2 + cursor_x,
                  cy2 + y,
                ),
              )
            @svg.CurveTo(cx1, cy1, cx2, cy2, ex, ey) =>
              translated.push(
                @svg.CurveTo(
                  cx1 + cursor_x,
                  cy1 + y,
                  cx2 + cursor_x,
                  cy2 + y,
                  ex + cursor_x,
                  ey + y,
                ),
              )
            @svg.ClosePath => translated.push(@svg.ClosePath)
            _ => ()
          }
        }
        let d = commands_to_path_d(translated)
        if d.length() > 0 {
          if path_d.to_string().length() > 0 {
            path_d.write_char(' ')
          }
          path_d.write_string(d)
        }
        cursor_x = cursor_x + advance
      }
      let d_str = path_d.to_string()
      if d_str.length() > 0 {
        result.write_string("<path d=\"")
        result.write_string(d_str)
        result.write_string("\"")
        result.write_string(fill_attr)
        result.write_string(" />\n")
      }
      i = end_pos
    } else {
      result.write_char(svg_str[i].to_int().unsafe_to_char())
      i = i + 1
    }
  }
  result.to_string()
}

///|
fn svg_string_to_image(
  svg_str : String,
  width : Int,
  height : Int,
  font_callback? : (Int, Double) -> (Array[@svg.PathCommand], Double),
) -> @svg.Image? {
  // Pre-process SVG: replace <text> with <path> if font is available
  let processed_svg = match font_callback {
    Some(cb) => replace_text_with_paths(svg_str, cb)
    None => svg_str
  }
  let node = @svg.parse_svg(processed_svg)
  match node {
    None => None
    Some(root) => {
      let image = @svg.Image::new(width, height)
      let setter : @svg.PixelSetter = {
        set: fn(x, y, color) {
          if x >= 0 && x < width && y >= 0 && y < height {
            image.set_pixel(x, y, color)
          }
        },
      }
      let scene = @svg.Scene::new(root)
      let bounds = scene.get_bounds()
      let vb : @svg.ViewBox = {
        min_x: bounds.min_x,
        min_y: bounds.min_y,
        width: bounds.max_x - bounds.min_x,
        height: bounds.max_y - bounds.min_y,
      }
      let par : @svg.PreserveAspectRatio = {
        align: XMidYMid,
        meet_or_slice: Meet,
      }
      let ctx = @svg.RenderContext::new(setter, width, height)
      scene.render_with_viewbox(ctx, vb, par)
      Some(image)
    }
  }
}

///|
fn image_to_rgb_bytes(image : @svg.Image) -> Bytes {
  let buf = @buffer.new(size_hint=image.width * image.height * 3)
  for y in 0..<image.height {
    for x in 0..<image.width {
      let c = image.get_pixel(x, y)
      buf.write_byte(c.r.to_byte())
      buf.write_byte(c.g.to_byte())
      buf.write_byte(c.b.to_byte())
    }
  }
  buf.to_bytes()
}

///|
pub fn render_svg_to_kitty_commands(
  svg_str : String,
  width : Int,
  height : Int,
  image_id : Int,
  font_callback? : (Int, Double) -> (Array[@svg.PathCommand], Double),
) -> Array[String]? {
  let image = svg_string_to_image(svg_str, width, height, font_callback?)
  match image {
    None => None
    Some(img) => {
      let rgb_bytes = image_to_rgb_bytes(img)
      let payload = @image.base64_encode(rgb_bytes[:])
      let commands = kitty_transmit_rgb(image_id, width, height, payload)
      Some(commands)
    }
  }
}
