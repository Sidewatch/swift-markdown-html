//
//  MarkdownHTML.swift
//  SwiftMarkdownHTML
//
//  Renders a CommonMark + GitHub-Flavored-Markdown document to HTML via Apple's
//  swift-markdown (cmark-gfm). Tables, task lists, strikethrough, nested lists,
//  images, code blocks, and raw HTML are all supported.
//
//  Created by David Sherlock on 7/9/26.
//

import Foundation
import Markdown

/// Renders Markdown to HTML.
///
/// A full CommonMark + GitHub-Flavored-Markdown document (parsed by Apple's
/// swift-markdown / cmark-gfm) is walked and emitted as HTML — tables, task
/// lists, strikethrough, nested lists, images, code blocks, raw HTML, the lot.
///
/// ```swift
/// import MarkdownHTML
///
/// let html = MarkdownHTML.render("# Hello\n\nSome **bold** text.")
/// // "<h1>Hello</h1>\n<p>Some <strong>bold</strong> text.</p>\n"
/// ```
public enum MarkdownHTML {

    /// Parses `markdown` and returns the rendered HTML.
    ///
    /// The input is treated as a complete Markdown document. Text and code are
    /// HTML-escaped; raw HTML embedded in the Markdown is passed through verbatim.
    ///
    /// - Parameters:
    ///   - markdown: The Markdown source to render.
    ///   - highlightCode: Optional syntax highlighter for fenced blocks. Given the block's
    ///     source and its fence tag (`swift`, `php`, …), it returns HTML for the inside of the
    ///     `<code>` element — already escaped — or nil to leave the block plain.
    ///
    ///     A closure rather than a dependency: highlighting means tree-sitter and a few dozen
    ///     grammars, and a Markdown-to-HTML library has no business pulling that in. The host
    ///     app owns both and wires them together, so this package stays what it says it is.
    /// - Returns: The rendered HTML fragment.
    public static func render(_ markdown: String,
                              highlightCode: ((String, String) -> String?)? = nil) -> String {
        let document = Markdown.Document(parsing: markdown)
        var renderer = HTMLRenderer(highlightCode: highlightCode)
        return renderer.visit(document)
    }
}

/// Walks a parsed Markdown tree and emits HTML for each node.
///
/// Kept private to the module: it is the rendering machinery behind
/// ``MarkdownHTML/render(_:)`` and not part of the public surface.
private struct HTMLRenderer: MarkupVisitor {

    /// Optional per-block syntax highlighter — see ``MarkdownHTML/render(_:highlightCode:)``.
    let highlightCode: ((String, String) -> String?)?

    typealias Result = String

    /// Renders a node's children in order and concatenates the results.
    mutating func defaultVisit(_ markup: Markup) -> String {
        markup.children.map { visit($0) }.joined()
    }

    mutating func visitText(_ text: Text) -> String { esc(text.string) }
    mutating func visitParagraph(_ p: Paragraph) -> String { "<p>\(defaultVisit(p))</p>\n" }
    mutating func visitHeading(_ h: Heading) -> String { "<h\(h.level)>\(defaultVisit(h))</h\(h.level)>\n" }
    mutating func visitEmphasis(_ e: Emphasis) -> String { "<em>\(defaultVisit(e))</em>" }
    mutating func visitStrong(_ s: Strong) -> String { "<strong>\(defaultVisit(s))</strong>" }
    mutating func visitStrikethrough(_ s: Strikethrough) -> String { "<del>\(defaultVisit(s))</del>" }
    mutating func visitInlineCode(_ c: InlineCode) -> String { "<code>\(esc(c.code))</code>" }
    mutating func visitBlockQuote(_ b: BlockQuote) -> String { "<blockquote>\(defaultVisit(b))</blockquote>\n" }
    mutating func visitUnorderedList(_ l: UnorderedList) -> String { "<ul>\n\(defaultVisit(l))</ul>\n" }
    mutating func visitOrderedList(_ l: OrderedList) -> String {
        let start = l.startIndex == 1 ? "" : " start=\"\(l.startIndex)\""
        return "<ol\(start)>\n\(defaultVisit(l))</ol>\n"
    }
    mutating func visitThematicBreak(_ t: ThematicBreak) -> String { "<hr>\n" }
    mutating func visitLineBreak(_ l: LineBreak) -> String { "<br>\n" }
    mutating func visitSoftBreak(_ s: SoftBreak) -> String { " " }
    mutating func visitInlineHTML(_ h: InlineHTML) -> String { h.rawHTML }
    mutating func visitHTMLBlock(_ h: HTMLBlock) -> String { h.rawHTML }

    mutating func visitCodeBlock(_ c: CodeBlock) -> String {
        let cls = c.language.map { " class=\"language-\(escAttr($0))\"" } ?? ""
        // Highlighted when a highlighter is supplied AND recognises the tag; otherwise the
        // escaped source exactly as before. An unknown tag, or no highlighter at all, renders
        // what it always did rather than something half-coloured.
        if let tag = c.language, let highlighted = highlightCode?(c.code, tag) {
            return "<pre><code\(cls)>\(highlighted)</code></pre>\n"
        }
        return "<pre><code\(cls)>\(esc(c.code))</code></pre>\n"
    }

    mutating func visitListItem(_ item: ListItem) -> String {
        let inner = defaultVisit(item)
        if let box = item.checkbox {
            let checked = box == .checked ? " checked" : ""
            return "<li class=\"task\"><input type=\"checkbox\" disabled\(checked)>\(inner)</li>\n"
        }
        return "<li>\(inner)</li>\n"
    }

    mutating func visitLink(_ l: Link) -> String {
        "<a href=\"\(escAttr(safeURL(l.destination ?? "")))\">\(defaultVisit(l))</a>"
    }

    mutating func visitImage(_ img: Image) -> String {
        "<img src=\"\(escAttr(safeURL(img.source ?? "", allowImageData: true)))\" alt=\"\(escAttr(img.plainText))\">"
    }

    // Tables (GFM)
    mutating func visitTable(_ table: Table) -> String {
        "<table>\n\(visit(table.head))\(visit(table.body))</table>\n"
    }
    mutating func visitTableHead(_ head: Table.Head) -> String {
        "<thead><tr>" + head.children.map { "<th>\(visit($0))</th>" }.joined() + "</tr></thead>\n"
    }
    mutating func visitTableBody(_ body: Table.Body) -> String {
        "<tbody>\n" + body.children.map { visit($0) }.joined() + "</tbody>\n"
    }
    mutating func visitTableRow(_ row: Table.Row) -> String {
        "<tr>" + row.children.map { "<td>\(visit($0))</td>" }.joined() + "</tr>\n"
    }
    mutating func visitTableCell(_ cell: Table.Cell) -> String { defaultVisit(cell) }

    /// Neutralizes dangerous URL schemes in a link/image destination.
    ///
    /// `javascript:`, `vbscript:`, and (unless `allowImageData` is set and the
    /// URI is an image) `data:` destinations are replaced with `"#"` so an
    /// untrusted document can't smuggle a script-executing URL into an
    /// `href`/`src`. The scheme check strips whitespace/control characters
    /// first, matching how browsers tolerate them inside URLs.
    private func safeURL(_ s: String, allowImageData: Bool = false) -> String {
        let scheme = String(s.lowercased().unicodeScalars.filter { $0.value > 0x20 })
        if scheme.hasPrefix("javascript:") || scheme.hasPrefix("vbscript:") { return "#" }
        if scheme.hasPrefix("data:") {
            return allowImageData && scheme.hasPrefix("data:image/") ? s : "#"
        }
        return s
    }

    /// Escapes `&`, `<`, and `>` for use in HTML text content.
    ///
    /// Single UTF-8 pass with a no-specials early return — this runs on every
    /// text/code node of the live preview's per-pause re-render, and the chained
    /// `replacingOccurrences` form it replaces bridged the string through
    /// NSString once per pattern.
    private func esc(_ s: String) -> String { escaped(s, forAttribute: false) }

    /// Escapes text-content characters plus `"` for use inside a quoted HTML attribute.
    private func escAttr(_ s: String) -> String { escaped(s, forAttribute: true) }

    private func escaped(_ s: String, forAttribute: Bool) -> String {
        let amp = UInt8(ascii: "&"), lt = UInt8(ascii: "<"), gt = UInt8(ascii: ">")
        let quot = UInt8(ascii: "\"")
        let utf8 = s.utf8
        guard utf8.contains(where: { $0 == amp || $0 == lt || $0 == gt || (forAttribute && $0 == quot) })
        else { return s }
        var out = [UInt8]()
        out.reserveCapacity(utf8.count + 16)
        for byte in utf8 {
            switch byte {
            case amp: out.append(contentsOf: "&amp;".utf8)
            case lt:  out.append(contentsOf: "&lt;".utf8)
            case gt:  out.append(contentsOf: "&gt;".utf8)
            case quot where forAttribute: out.append(contentsOf: "&quot;".utf8)
            default:  out.append(byte)
            }
        }
        return String(decoding: out, as: UTF8.self)
    }
}
