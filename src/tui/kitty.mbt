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
fn kitty_delete_all_visible() -> String {
  "\u001b_Ga=d,d=a\u001b\\"
}

///|
fn svg_string_to_image(
  svg_str : String,
  width : Int,
  height : Int,
) -> @svg.Image? {
  let node = @svg.parse_svg(svg_str)
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
fn render_svg_to_kitty_commands(
  svg_str : String,
  width : Int,
  height : Int,
  image_id : Int,
) -> Array[String]? {
  let image = svg_string_to_image(svg_str, width, height)
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
