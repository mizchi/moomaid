///|
pub fn split_lines(text : String) -> Array[String] {
  let out : Array[String] = []
  for part in text.split("\n") {
    out.push(part.to_string())
  }
  out
}

///|
pub fn trim_line(line : String) -> String {
  line.trim().to_string()
}

///|
pub fn split_ws(line : String) -> Array[String] {
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
pub fn split_once(text : String, sep : String) -> (String, String)? {
  let parts : Array[String] = []
  for part in text.split(sep) {
    parts.push(part.to_string())
  }
  if parts.length() < 2 {
    return None
  }
  let first = parts[0]
  if parts.length() == 2 {
    return Some((first, parts[1]))
  }
  let sb = StringBuilder::new()
  for i in 1..<parts.length() {
    if i > 1 {
      sb.write_view(sep)
    }
    sb.write_view(parts[i])
  }
  Some((first, sb.to_string()))
}

///|
pub fn drop_first_char(text : String) -> String {
  let sb = StringBuilder::new()
  let mut first = true
  for c in text {
    if first {
      first = false
    } else {
      sb.write_char(c)
    }
  }
  sb.to_string()
}

///|
pub fn strip_quotes(text : String) -> String {
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
pub fn max_int(a : Int, b : Int) -> Int {
  if a > b {
    a
  } else {
    b
  }
}

///|
pub fn max_len(lines : Array[String]) -> Int {
  let mut m = 0
  for line in lines {
    m = max_int(m, line.length())
  }
  m
}
