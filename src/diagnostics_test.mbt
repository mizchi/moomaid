///|
test "parse_checked reports an empty document at the first character" {
  match parse_checked("") {
    Err(error) => {
      inspect(error.line, content="1")
      inspect(error.column, content="1")
      inspect(error.message, content="expected a Mermaid diagram header")
    }
    Ok(_) => inspect(false, content="true")
  }
}

///|
test "parse_checked reports an unsupported diagram header" {
  match parse_checked("sankey\n  A,B,10") {
    Err(error) => {
      inspect(error.line, content="1")
      inspect(error.column, content="1")
      inspect(error.message, content="unsupported Mermaid diagram type: sankey")
    }
    Ok(_) => inspect(false, content="true")
  }
}

///|
test "parse_checked reports a missing flowchart edge target" {
  match parse_checked("flowchart LR\n  API -->") {
    Err(error) => {
      inspect(error.line, content="2")
      inspect(error.column, content="10")
      inspect(error.message, content="expected a target node after '-->'")
    }
    Ok(_) => inspect(false, content="true")
  }
}

///|
test "parse_checked reports an unterminated subgraph" {
  match parse_checked("flowchart LR\n  subgraph API\n    App[App]") {
    Err(error) => {
      inspect(error.line, content="2")
      inspect(error.column, content="3")
      inspect(error.message, content="unterminated subgraph")
    }
    Ok(_) => inspect(false, content="true")
  }
}

///|
test "parse_checked reports an unexpected subgraph end" {
  match parse_checked("flowchart LR\n  end") {
    Err(error) => {
      inspect(error.line, content="2")
      inspect(error.column, content="3")
      inspect(
        error.message,
        content="unexpected 'end' without a matching subgraph",
      )
    }
    Ok(_) => inspect(false, content="true")
  }
}

///|
test "render_checked returns ASCII and SVG artifacts on success" {
  match render_checked("flowchart LR\n  A --> B", OutputFormat::Ascii) {
    Ok(ascii) => inspect(ascii.contains("A"), content="true")
    Err(_) => inspect(false, content="true")
  }
  match render_checked("flowchart LR\n  A --> B", OutputFormat::Svg) {
    Ok(svg) => inspect(svg.has_prefix("<svg"), content="true")
    Err(_) => inspect(false, content="true")
  }
}
