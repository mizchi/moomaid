///|
test "parse_options accepts SVG presentation flags" {
  match
    parse_options([
      "moomaid-skill", "--format", "svg", "--theme", "github-dark", "--font", "Fira Code",
      "--padding", "32", "--background", "#112233", "--transparent", "--title", "Order flow",
      "--description", "Creates an order",
    ]) {
    Ok(options) => {
      let is_expected = options.format == @mermaid.OutputFormat::Svg &&
        options.theme == Some("github-dark") &&
        options.font == Some("Fira Code") &&
        options.padding == Some(32) &&
        options.background == Some("#112233") &&
        options.transparent &&
        options.title == Some("Order flow") &&
        options.description == Some("Creates an order")
      inspect(is_expected, content="true")
    }
    Err(_) => inspect(false, content="true")
  }
}

///|
test "parse_options rejects a non-numeric padding value" {
  match parse_options(["moomaid-skill", "--padding", "wide"]) {
    Err(message) =>
      inspect(message, content="--padding must be a positive integer")
    Ok(_) => inspect(false, content="true")
  }
}
