///|
test "renders a mindmap as an indented outline" {
  let source = "mindmap\n  root((Architecture))\n    API\n      Auth"
  match render_checked(source, OutputFormat::Ascii) {
    Ok(ascii) => {
      inspect(ascii.contains("Mindmap"), content="true")
      inspect(ascii.contains("Architecture"), content="true")
      inspect(ascii.contains("Auth"), content="true")
    }
    Err(_) => inspect(false, content="true")
  }
}

///|
test "renders journey sections and tasks" {
  let source = "journey\n  title Checkout\n  section Customer\n    Submit order: 5: Customer\n  section System\n    Reserve stock: 3: API"
  match render_checked(source, OutputFormat::Ascii) {
    Ok(ascii) => {
      inspect(ascii.contains("Journey: Checkout"), content="true")
      inspect(ascii.contains("Customer"), content="true")
      inspect(ascii.contains("Reserve stock"), content="true")
    }
    Err(_) => inspect(false, content="true")
  }
}

///|
test "renders pie entries to SVG" {
  let source = "pie title Language share\n  \"MoonBit\" : 40\n  \"Other\" : 60"
  match render_checked(source, OutputFormat::Svg) {
    Ok(svg) => {
      inspect(svg.contains("Pie: Language share"), content="true")
      inspect(svg.contains("MoonBit"), content="true")
      inspect(svg.contains("Other"), content="true")
    }
    Err(_) => inspect(false, content="true")
  }
}
