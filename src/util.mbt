///|
fn split_lines(text : String) -> Array[String] {
  let out : Array[String] = []
  for part in text.split("\n") {
    out.push(part.to_string())
  }
  out
}

///|
fn trim_line(line : String) -> String {
  line.trim().to_string()
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
      left = part.to_string()
      first = false
    } else if not(found) {
      sb.write_string(part.to_string())
      found = true
    } else {
      sb.write_string(sep)
      sb.write_string(part.to_string())
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
  let t = text.trim().to_string()
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
fn max_len(lines : Array[String]) -> Int {
  let mut m = 0
  for line in lines {
    m = max_int(m, line.length())
  }
  m
}
