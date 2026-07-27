///|
/// Print the stable command contract for the Mooncakes skill package.
fn print_usage() -> Unit {
  println("Usage: moomaid-skill [--format ascii|svg] < Mermaid.mmd")
}

///|
/// Parse the skill's intentionally small command API.
fn parse_format(args : Array[String]) -> @mermaid.OutputFormat? {
  if args.length() == 1 {
    Some(@mermaid.OutputFormat::Ascii)
  } else if args.length() == 3 && args[1] == "--format" {
    @mermaid.OutputFormat::parse(args[2])
  } else {
    None
  }
}

///|
/// Read Mermaid source from standard input and write one rendered artifact.
fn main {
  match parse_format(@env.args()) {
    None => print_usage()
    Some(format) => {
      let source = @fs.read_file_to_string("/dev/stdin") catch {
        @fs.IOError(message) => {
          println("moomaid: unable to read standard input: " + message)
          return
        }
      }
      println(@mermaid.render(source, format))
    }
  }
}
