///|
test "skill rendering API selects the requested format" {
  let source = "flowchart TD\n  A --> B\n"
  let ascii = render(source, OutputFormat::Ascii)
  let svg = render(source, OutputFormat::Svg)
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
  match OutputFormat::parse("ascii") {
    Some(OutputFormat::Ascii) => ()
    _ => fail("expected ASCII format")
  }
  match OutputFormat::parse("svg") {
    Some(OutputFormat::Svg) => ()
    _ => fail("expected SVG format")
  }
  match OutputFormat::parse("html") {
    None => ()
    _ => fail("expected an unknown format to be rejected")
  }
}
