///|
pub struct DiagramColors {
  bg : String
  fg : String
  line : String
  accent : String
  muted : String
  surface : String
  border : String
} derive(Show, Eq)

///|
pub struct RenderOptions {
  bg : String?
  fg : String?
  line : String?
  accent : String?
  muted : String?
  surface : String?
  border : String?
  font : String?
  transparent : Bool?
} derive(Show, Eq)

///|
pub struct AsciiRenderOptions {
  use_ascii : Bool
  padding_x : Int
  padding_y : Int
  box_border_padding : Int
} derive(Show, Eq)

///|
pub struct Defaults {
  bg : String
  fg : String
} derive(Show, Eq)

///|
pub let defaults : Defaults = { bg: "#FFFFFF", fg: "#27272A" }

///|
pub fn default_render_options() -> RenderOptions {
  {
    bg: None,
    fg: None,
    line: None,
    accent: None,
    muted: None,
    surface: None,
    border: None,
    font: Some("Inter"),
    transparent: Some(false),
  }
}

///|
pub fn default_ascii_options() -> AsciiRenderOptions {
  { use_ascii: false, padding_x: 2, padding_y: 1, box_border_padding: 1 }
}

///|
fn[T] opt_or(value : T?, fallback : T) -> T {
  match value {
    Some(v) => v
    None => fallback
  }
}

///|
pub fn build_colors(options : RenderOptions) -> DiagramColors {
  let bg = opt_or(options.bg, defaults.bg)
  let fg = opt_or(options.fg, defaults.fg)
  let line = opt_or(options.line, fg)
  let accent = opt_or(options.accent, fg)
  let muted = opt_or(options.muted, fg)
  let surface = opt_or(options.surface, bg)
  let border = opt_or(options.border, fg)
  { bg, fg, line, accent, muted, surface, border }
}

///|
pub fn resolve_font(options : RenderOptions) -> String {
  opt_or(options.font, "Inter")
}

///|
pub fn resolve_transparent(options : RenderOptions) -> Bool {
  opt_or(options.transparent, false)
}

///|
pub fn from_syntree_theme(theme : @highlight.HighlightTheme) -> DiagramColors {
  {
    bg: theme.background,
    fg: theme.foreground,
    line: theme.punctuation,
    accent: theme.keyword,
    muted: theme.comment,
    surface: theme.background,
    border: theme.punctuation,
  }
}

///|
fn make_themes() -> Map[String, DiagramColors] {
  let map : Map[String, DiagramColors] = Map::new()
  map.set("github-dark", from_syntree_theme(@highlight.github_dark()))
  map.set("github-light", from_syntree_theme(@highlight.github_light()))
  map.set("one-dark-pro", from_syntree_theme(@highlight.one_dark_pro()))
  map.set("vitesse-dark", from_syntree_theme(@highlight.vitesse_dark()))
  map
}

///|
pub let themes : Map[String, DiagramColors] = make_themes()
