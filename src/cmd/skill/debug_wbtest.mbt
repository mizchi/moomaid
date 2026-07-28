///|
test "parse_options accepts debug layout only for SVG" {
  match parse_options(["moomaid-skill", "--format", "svg", "--debug-layout"]) {
    Ok(options) => assert_true(options.debug_layout)
    Err(_) => assert_true(false)
  }
}

///|
test "parse_options rejects debug layout with ASCII output" {
  match parse_options(["moomaid-skill", "--debug-layout"]) {
    Ok(_) => assert_true(false)
    Err(message) => assert_true(message.contains("SVG presentation options"))
  }
}
