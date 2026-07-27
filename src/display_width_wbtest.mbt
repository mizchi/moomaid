///|
/// Terminal display-width rules are intentionally independent from UTF-16 length.
test "display_width handles wide and zero-width characters" {
  assert_eq(display_width("日本語"), 6)
  assert_eq(display_width("🙂"), 2)
  assert_eq(display_width("é"), 1)
  assert_eq(display_width("👩‍💻"), 2)
}

///|
/// Text drawing advances by display columns, not by Unicode code units.
test "canvas aligns wide text with following columns" {
  let canvas = Canvas::new(8, 1)
  canvas.draw_text(0, 0, "日本")
  canvas.set(4, 0, '|')
  assert_eq(canvas.render(), "日本|")
}

///|
/// Combining marks and ZWJ emoji sequences stay in their preceding display cell.
test "canvas preserves grapheme extensions" {
  let canvas = Canvas::new(8, 1)
  canvas.draw_text(0, 0, "é")
  canvas.set(1, 0, '|')
  assert_eq(canvas.render(), "é|")

  let emoji_canvas = Canvas::new(8, 1)
  emoji_canvas.draw_text(0, 0, "👩‍💻")
  emoji_canvas.set(2, 0, '|')
  assert_eq(emoji_canvas.render(), "👩‍💻|")
}

///|
/// Graph layout uses terminal columns when sizing node borders.
test "graph rendering contains wide labels inside their borders" {
  let rendered = render_to_string("flowchart TD\n  A[日本語] --> B[🙂]\n")
  assert_eq(
    rendered, "┌────────┐\n│ 日本語 │\n└────────┘\n     │\n     │\n  ┌────┐\n  │ 🙂 │\n  └────┘",
  )
}

///|
/// Sequence actor widths and message positions use the same display-width rule.
test "sequence rendering aligns wide actor and message labels" {
  let rendered = render_to_string(
    "sequenceDiagram\n  participant 利用者\n  participant API\n  利用者->>API: 検索🙂\n",
  )
  assert_eq(
    rendered, "  ┌──────────┐      ┌───────┐\n  │ 利用者   │      │ API   │\n  └──────────┘      └───────┘\n        │検索🙂         │\n        ────────────────▶\n        │               │",
  )
}
