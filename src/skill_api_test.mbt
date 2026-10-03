///|
test "skill rendering API selects the requested format" {
  let source = "flowchart TD\n  A --> B\n"
  let ascii = @moomaid.render(source, @moomaid.OutputFormat::Ascii)
  let svg = @moomaid.render(source, @moomaid.OutputFormat::Svg)
  if ascii.length() == 0 {
    fail("expected ASCII output")
  }
  if !svg.has_prefix("<svg") {
    fail("expected SVG output")
  }
  if ascii == svg {
    fail("expected distinct output formats")
  }
}

///|
test "skill output formats have a stable textual API" {
  match @moomaid.OutputFormat::parse("ascii") {
    Some(@moomaid.OutputFormat::Ascii) => ()
    _ => fail("expected ASCII format")
  }
  match @moomaid.OutputFormat::parse("svg") {
    Some(@moomaid.OutputFormat::Svg) => ()
    _ => fail("expected SVG format")
  }
  match @moomaid.OutputFormat::parse("html") {
    None => ()
    _ => fail("expected an unknown format to be rejected")
  }
}
