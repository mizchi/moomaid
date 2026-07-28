///|
test "SVG theme options keep caller-provided font and padding" {
  match svg_options_from_theme("github-dark", font="Fira Code", padding=32) {
    Some(options) => {
      inspect(options.font == Some("Fira Code"), content="true")
      inspect(options.padding == Some(32), content="true")
    }
    None => inspect(false, content="true")
  }
}

///|
test "SVG options can override the background color" {
  let options = default_svg_options().with_background("#112233")
  inspect(options.bg == Some("#112233"), content="true")
}

///|
test "checked SVG rendering honors the configured padding" {
  let options = default_svg_options().with_padding(32)
  match render_svg_checked("flowchart LR\n  A --> B", options~) {
    Ok(svg) => inspect(svg.contains("translate(32,32)"), content="true")
    Err(_) => inspect(false, content="true")
  }
}
