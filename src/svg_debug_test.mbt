///|
test "public SVG API enables layout diagnostics" {
  let svg = @moomaid.experimental_render_to_svg(
    "flowchart LR\n  A --> B",
    options=@moomaid.default_svg_options().with_debug_layout(),
  )
  assert_true(svg.contains("debug-layout"))
}
