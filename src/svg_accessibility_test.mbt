///|
test "SVG has an accessible fallback label" {
  let svg = experimental_render_to_svg("flowchart LR\n  A --> B")
  inspect(svg.contains("role=\"img\""), content="true")
  inspect(svg.contains("aria-label=\"Mermaid diagram\""), content="true")
}

///|
test "SVG embeds a caller-provided title and description" {
  let options = default_svg_options()
    .with_title("Order flow")
    .with_description("Browser creates an order through the API.")
  match render_svg_checked("flowchart LR\n  A --> B", options~) {
    Ok(svg) => {
      inspect(
        svg.contains("aria-labelledby=\"moomaid-title moomaid-description\""),
        content="true",
      )
      inspect(
        svg.contains("<title id=\"moomaid-title\">Order flow</title>"),
        content="true",
      )
      inspect(
        svg.contains(
          "<desc id=\"moomaid-description\">Browser creates an order through the API.</desc>",
        ),
        content="true",
      )
    }
    Err(_) => inspect(false, content="true")
  }
}
