# Mermaid API

## render_to_string

```mbt check
///|
test {
  let text =
    #|graph TD
    #|  A --> B
    #|
  let ascii = render_to_string(text)
  assert_true(ascii.contains("A"))
  assert_true(ascii.contains("B"))
}
```

## theme

```mbt check
///|
test {
  let opts = svg_options_from_theme("github-dark")
  assert_true(opts is Some(_))
}
```
