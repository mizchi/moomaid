# Visual check examples

各ファイルは単一のMermaidダイアグラムです。ASCII出力は次のように確認できます。

```bash
just cli examples/visual-check/subgraph.mmd
just cli examples/visual-check/sequence.mmd
just cli examples/visual-check/timeline.mmd
just cli examples/visual-check/gitgraph.mmd
just cli examples/visual-check/gantt.mmd
just cli examples/visual-check/mindmap.mmd
just cli examples/visual-check/journey.mmd
just cli examples/visual-check/pie.mmd
```

SVGの目視確認はHTMLを生成してブラウザで開きます。

```bash
just cli --html examples/visual-check/sequence.mmd > /tmp/moomaid-preview.html
open /tmp/moomaid-preview.html
```

レイアウト上の潜在的な重なりを確認するには、Wasm skill のデバッグ SVG を使います。

```bash
moon runwasm src/cmd/skill --format svg --debug-layout < examples/visual-check/subgraph.mmd > /tmp/moomaid-debug.svg
open /tmp/moomaid-debug.svg
```

ノード枠は青、エッジラベルは緑、subgraph 見出しは紫、エッジ経路は橙、
衝突候補は赤で表示されます。
