# Mermaid API

## render_mermaid_ascii

```mbt check
///|
test {
  let text =
    #|graph TD
    #|  A --> B
    #|
  let ascii = render_mermaid_ascii(text)
  assert_true(ascii.contains("A"))
  assert_true(ascii.contains("B"))
}
```

## theme

```mbt check
///|
test {
  let colors = from_syntree_theme(@highlight.github_dark())
  assert_true(colors.bg.length() > 0)
  assert_true(colors.fg.length() > 0)
}
```
