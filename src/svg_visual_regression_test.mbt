///|
test "SVG visual regression for subgraphs and CJK edge labels" {
  let source =
    #|flowchart LR
    #|  subgraph Client
    #|    Browser[ブラウザ]
    #|  end
    #|  subgraph Service
    #|    API[注文 API]
    #|  end
    #|  Browser -->|注文を送信| API
    #|
  let options = default_svg_options()
    .with_padding(24)
    .with_title("Order submission")
  match render_svg_checked(source, options~) {
    Ok(svg) =>
      inspect(
        svg,
        content=(
          #|<svg xmlns="http://www.w3.org/2000/svg" width="468" height="174" viewBox="0 0 468 174" role="img" aria-labelledby="moomaid-title"><title id="moomaid-title">Order submission</title>
          #|<rect x="0" y="0" width="468" height="174" fill="#FFFFFF" />
          #|<defs>
          #|  <marker id="arrow" markerWidth="8" markerHeight="8" refX="7" refY="4" orient="auto" markerUnits="strokeWidth">
          #|    <path d="M0,0 L8,4 L0,8 z" fill="#27272A" />
          #|  </marker>
          #|</defs>
          #|<g transform="translate(24,24)">
          #|<g class="subgraphs">
          #|<rect x="30" y="18" width="140" height="90" rx="8" ry="8" fill="none" stroke="#27272A" stroke-width="1" stroke-dasharray="4,3" />
          #|<rect x="270" y="18" width="140" height="90" rx="8" ry="8" fill="none" stroke="#27272A" stroke-width="1" stroke-dasharray="4,3" />
          #|</g>
          #|<g class="edges">
          #|<path d="M 160 54 L 280 54" fill="none" stroke="#27272A" stroke-width="1.5" marker-end="url(#arrow)" />
          #|<rect x="176.4" y="43.36" width="87.2" height="21.28" rx="3" fill="#FFFFFF" />
          #|<text x="220" y="54" font-size="14.4" fill="#27272A" text-anchor="middle" dominant-baseline="central" font-family="Inter">注文を送信</text>
          #|</g>
          #|<g class="subgraph-labels">
          #|<rect x="34" y="20" width="55.52000000000001" height="21.28" rx="3" fill="#FFFFFF" />
          #|<text x="38" y="32.4" font-size="14.4" fill="#27272A" font-family="Inter">Client</text>
          #|<rect x="274" y="20" width="63.440000000000005" height="21.28" rx="3" fill="#FFFFFF" />
          #|<text x="278" y="32.4" font-size="14.4" fill="#27272A" font-family="Inter">Service</text>
          #|</g>
          #|<g class="nodes">
          #|<g id="Browser">
          #|<rect x="40" y="36" width="120" height="54" rx="4" ry="4" fill="#FFFFFF" stroke="#27272A" stroke-width="1.2" />
          #|<text x="60" y="68.4" font-size="14.4" fill="#27272A" font-family="Inter">ブラウザ</text>
          #|</g>
          #|<g id="API">
          #|<rect x="280" y="36" width="120" height="54" rx="4" ry="4" fill="#FFFFFF" stroke="#27272A" stroke-width="1.2" />
          #|<text x="300" y="68.4" font-size="14.4" fill="#27272A" font-family="Inter">注文 API</text>
          #|</g>
          #|</g>
          #|</g>
          #|</svg>
        ),
      )
    Err(error) => inspect(error.display())
  }
}
