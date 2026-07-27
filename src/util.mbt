///|
fn split_lines(text : String) -> Array[String] {
  let out : Array[String] = []
  for part in text.split("\n") {
    out.push(part.to_owned())
  }
  out
}

///|
fn trim_line(line : String) -> String {
  line.trim().to_owned()
}

///|
fn split_ws(line : String) -> Array[String] {
  let out : Array[String] = []
  let mut sb = StringBuilder::new()
  let mut has = false
  for c in line {
    if c is (' ' | '\t' | '\n' | '\r') {
      if has {
        out.push(sb.to_string())
        sb = StringBuilder::new()
        has = false
      }
    } else {
      sb.write_char(c)
      has = true
    }
  }
  if has {
    out.push(sb.to_string())
  }
  out
}

///|
fn split_once(text : String, sep : String) -> (String, String)? {
  let mut first = true
  let mut left : String = ""
  let sb = StringBuilder::new()
  let mut found = false
  for part in text.split(sep) {
    if first {
      left = part.to_owned()
      first = false
    } else if !found {
      sb.write_string(part.to_owned())
      found = true
    } else {
      sb.write_string(sep)
      sb.write_string(part.to_owned())
    }
  }
  if found {
    Some((left, sb.to_string()))
  } else {
    None
  }
}

///|
fn drop_first_char(text : String) -> String {
  if text.length() <= 1 {
    return ""
  }
  let iter = text.iter()
  let _ = iter.next()
  let sb = StringBuilder::new()
  for c in iter {
    sb.write_char(c)
  }
  sb.to_string()
}

///|
fn strip_quotes(text : String) -> String {
  let t = text.trim().to_owned()
  if t.has_prefix("\"") && t.has_suffix("\"") && t.length() >= 2 {
    let sb = StringBuilder::new()
    let len = t.length()
    let mut i = 0
    for c in t {
      if i > 0 && i < len - 1 {
        sb.write_char(c)
      }
      i += 1
    }
    sb.to_string()
  } else {
    t
  }
}

///|
fn max_int(a : Int, b : Int) -> Int {
  if a > b {
    a
  } else {
    b
  }
}

///|
/// Returns whether a code point extends the preceding terminal cell.
fn is_zero_width_code_point(code_point : Int) -> Bool {
  code_point < 0x20 ||
  (code_point >= 0x7F && code_point <= 0x9F) ||
  (code_point >= 0x0300 && code_point <= 0x036F) ||
  (code_point >= 0x0483 && code_point <= 0x0489) ||
  (code_point >= 0x0591 && code_point <= 0x05BD) ||
  code_point == 0x05BF ||
  (code_point >= 0x05C1 && code_point <= 0x05C2) ||
  (code_point >= 0x05C4 && code_point <= 0x05C5) ||
  code_point == 0x05C7 ||
  (code_point >= 0x0610 && code_point <= 0x061A) ||
  (code_point >= 0x064B && code_point <= 0x065F) ||
  code_point == 0x0670 ||
  (code_point >= 0x06D6 && code_point <= 0x06ED) ||
  (code_point >= 0x0711 && code_point <= 0x0711) ||
  (code_point >= 0x0730 && code_point <= 0x074A) ||
  (code_point >= 0x07A6 && code_point <= 0x07B0) ||
  (code_point >= 0x07EB && code_point <= 0x07F3) ||
  (code_point >= 0x0816 && code_point <= 0x0819) ||
  (code_point >= 0x081B && code_point <= 0x0823) ||
  (code_point >= 0x0825 && code_point <= 0x0827) ||
  (code_point >= 0x0829 && code_point <= 0x082D) ||
  (code_point >= 0x0859 && code_point <= 0x085B) ||
  (code_point >= 0x08D3 && code_point <= 0x0902) ||
  (code_point >= 0x093A && code_point <= 0x093C) ||
  (code_point >= 0x0941 && code_point <= 0x0948) ||
  code_point == 0x094D ||
  (code_point >= 0x0951 && code_point <= 0x0957) ||
  (code_point >= 0x0962 && code_point <= 0x0963) ||
  (code_point >= 0x1AB0 && code_point <= 0x1AFF) ||
  (code_point >= 0x1DC0 && code_point <= 0x1DFF) ||
  code_point == 0x200D ||
  (code_point >= 0x20D0 && code_point <= 0x20FF) ||
  (code_point >= 0xFE00 && code_point <= 0xFE0F) ||
  (code_point >= 0xFE20 && code_point <= 0xFE2F) ||
  (code_point >= 0x1F3FB && code_point <= 0x1F3FF) ||
  (code_point >= 0xE0100 && code_point <= 0xE01EF)
}

///|
/// Returns whether a code point occupies two terminal columns.
fn is_wide_code_point(code_point : Int) -> Bool {
  code_point >= 0x1100 &&
  (
    code_point <= 0x115F ||
    code_point == 0x2329 ||
    code_point == 0x232A ||
    (code_point >= 0x2E80 && code_point <= 0xA4CF && code_point != 0x303F) ||
    (code_point >= 0xAC00 && code_point <= 0xD7A3) ||
    (code_point >= 0xF900 && code_point <= 0xFAFF) ||
    (code_point >= 0xFE10 && code_point <= 0xFE19) ||
    (code_point >= 0xFE30 && code_point <= 0xFE6F) ||
    (code_point >= 0xFF00 && code_point <= 0xFF60) ||
    (code_point >= 0xFFE0 && code_point <= 0xFFE6) ||
    (code_point >= 0x1F300 && code_point <= 0x1FAFF) ||
    (code_point >= 0x20000 && code_point <= 0x2FFFD) ||
    (code_point >= 0x30000 && code_point <= 0x3FFFD)
  )
}

///|
/// Returns the terminal-column width of one Unicode scalar value.
fn char_display_width(char : Char) -> Int {
  let code_point = char.to_int()
  if is_zero_width_code_point(code_point) {
    0
  } else if is_wide_code_point(code_point) {
    2
  } else {
    1
  }
}

///|
/// Returns whether a code point is a regional-indicator emoji.
fn is_regional_indicator(code_point : Int) -> Bool {
  code_point >= 0x1F1E6 && code_point <= 0x1F1FF
}

///|
/// Returns terminal display columns, grouping ZWJ emoji and flag pairs.
fn display_width(text : String) -> Int {
  let mut width = 0
  let mut join_next = false
  let mut regional_indicator_count = 0
  for char in text {
    let code_point = char.to_int()
    if is_zero_width_code_point(code_point) {
      if code_point == 0x200D {
        join_next = true
      }
    } else if join_next {
      join_next = false
      regional_indicator_count = 0
    } else if is_regional_indicator(code_point) && regional_indicator_count == 1 {
      regional_indicator_count = 0
    } else {
      width += char_display_width(char)
      regional_indicator_count = if is_regional_indicator(code_point) {
        1
      } else {
        0
      }
    }
  }
  width
}

///|
fn max_len(lines : Array[String]) -> Int {
  let mut m = 0
  for line in lines {
    m = max_int(m, display_width(line))
  }
  m
}
