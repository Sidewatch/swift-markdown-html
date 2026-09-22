# Swift Markdown HTML

A small Markdown → HTML renderer built on Apple's [swift-markdown](https://github.com/apple/swift-markdown) (cmark-gfm) — its only dependency. Give it a CommonMark + GitHub-Flavored-Markdown string and get back an HTML fragment: one static call, no configuration.

- Module `MarkdownHTML` in `Sources/MarkdownHTML`; tests in `Tests`; `swift test` is the whole check.
- Swift 6 language mode, tools 6.2, macOS 14+, no dependencies unless the README says so.
- Part of the Sidewatch package family; every package follows the same layout and PR rules.

## Module map

- `Core/` — the engine: MarkdownHTML (`render(_:highlightCode:math:diagramFences:)`; a diagram fence is `<pre class="TAG">` of its source), MathSpans (`$…$` / `$$…$$` lifted out before the parse as private-use placeholders and restored after as `.math` spans; fences, inline code and `\$` excluded)

## Rules

Read `CONTRIBUTING.md` before changing anything: it is the layout and PR rulebook for this package.

- **Auditing? Read `AUDIT.md` first** — what the last full audit checked and fixed, and the known non-issues to skip; extend it, do not redo it.
