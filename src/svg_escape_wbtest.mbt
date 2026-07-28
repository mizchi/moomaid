///|
test "SVG presentation values are escaped as XML attributes" {
  let options = default_svg_options()
    .with_font("Example\" data-check=\"injected")
    .with_background("#fff\" data-check=\"injected")
  let svg = experimental_render_to_svg("flowchart LR\n  A --> B", options~)
  assert_true(
    svg.contains("font-family=\"Example&quot; data-check=&quot;injected\""),
  )
  assert_true(svg.contains("fill=\"#fff&quot; data-check=&quot;injected\""))
  assert_true(!svg.contains("data-check=\"injected\""))
}
