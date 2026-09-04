# Swift Markdown HTML

A small Markdown → HTML renderer built on Apple's [swift-markdown](https://github.com/apple/swift-markdown) (cmark-gfm) — its only dependency. Give it a CommonMark + GitHub-Flavored-Markdown string and get back an HTML fragment: one static call, no configuration.

- Module `MarkdownHTML` in `Sources/MarkdownHTML`; tests in `Tests`; `swift test` is the whole check.
- Swift 6 language mode, tools 6.0, macOS 14+, no dependencies unless the README says so.
- Part of the Sidewatch package family; every package follows the same layout and PR rules.

## Module map

- `Core/` — the engine: MarkdownHTML

## Rules

Read `CONTRIBUTING.md` before changing anything: it is the layout and PR rulebook for this package.
