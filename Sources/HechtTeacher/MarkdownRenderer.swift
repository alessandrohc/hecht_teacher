import AppKit

enum MarkdownRenderer {

    static func render(_ source: String, baseSize: CGFloat = 13) -> NSAttributedString {
        let baseFont = NSFont.systemFont(ofSize: baseSize)
        let result = NSMutableAttributedString()
        let lines = source.components(separatedBy: "\n")

        for line in lines {
            let trimmedRight = line.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression)

            if let heading = parseHeading(trimmedRight) {
                let size: CGFloat
                switch heading.level {
                case 1: size = baseSize + 6
                case 2: size = baseSize + 3
                default: size = baseSize + 1
                }
                let font = NSFont.systemFont(ofSize: size, weight: .bold)
                let para = paragraphStyle(before: 8, after: 2)
                let body = renderInline(heading.text, baseFont: font, paragraph: para)
                result.append(body)
                result.append(newline(with: font, paragraph: para))
            } else if let item = parseBullet(trimmedRight) {
                let para = paragraphStyle(before: 0, after: 0, headIndent: 18)
                let bullet = NSAttributedString(string: "•\t", attributes: [
                    .font: baseFont,
                    .foregroundColor: NSColor.labelColor,
                    .paragraphStyle: para
                ])
                let body = renderInline(item, baseFont: baseFont, paragraph: para)
                result.append(bullet)
                result.append(body)
                result.append(newline(with: baseFont, paragraph: para))
            } else if let (number, text) = parseNumbered(trimmedRight) {
                let para = paragraphStyle(before: 0, after: 0, headIndent: 22)
                let prefix = NSAttributedString(string: "\(number).\t", attributes: [
                    .font: baseFont,
                    .foregroundColor: NSColor.labelColor,
                    .paragraphStyle: para
                ])
                let body = renderInline(text, baseFont: baseFont, paragraph: para)
                result.append(prefix)
                result.append(body)
                result.append(newline(with: baseFont, paragraph: para))
            } else if trimmedRight.trimmingCharacters(in: .whitespaces).isEmpty {
                result.append(newline(with: baseFont, paragraph: paragraphStyle(before: 0, after: 4)))
            } else {
                let para = paragraphStyle(before: 0, after: 2)
                let body = renderInline(trimmedRight, baseFont: baseFont, paragraph: para)
                result.append(body)
                result.append(newline(with: baseFont, paragraph: para))
            }
        }

        return result
    }

    private static func paragraphStyle(before: CGFloat = 0, after: CGFloat = 0, headIndent: CGFloat = 0) -> NSParagraphStyle {
        let p = NSMutableParagraphStyle()
        p.paragraphSpacing = after
        p.paragraphSpacingBefore = before
        p.headIndent = headIndent
        p.firstLineHeadIndent = 0
        p.lineHeightMultiple = 1.15
        return p
    }

    private static func newline(with font: NSFont, paragraph: NSParagraphStyle) -> NSAttributedString {
        return NSAttributedString(string: "\n", attributes: [.font: font, .paragraphStyle: paragraph])
    }

    private static func parseHeading(_ line: String) -> (level: Int, text: String)? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("#") else { return nil }
        var level = 0
        var idx = trimmed.startIndex
        while idx < trimmed.endIndex && trimmed[idx] == "#" && level < 6 {
            level += 1
            idx = trimmed.index(after: idx)
        }
        guard idx < trimmed.endIndex, trimmed[idx] == " " else { return nil }
        let text = String(trimmed[trimmed.index(after: idx)...]).trimmingCharacters(in: .whitespaces)
        return (level, text)
    }

    private static func parseBullet(_ line: String) -> String? {
        let stripped = String(line.drop(while: { $0 == " " }))
        if stripped.hasPrefix("- ") { return String(stripped.dropFirst(2)) }
        if stripped.hasPrefix("* ") && !stripped.hasPrefix("**") { return String(stripped.dropFirst(2)) }
        return nil
    }

    private static func parseNumbered(_ line: String) -> (Int, String)? {
        let stripped = String(line.drop(while: { $0 == " " }))
        var digits = ""
        var i = stripped.startIndex
        while i < stripped.endIndex, stripped[i].isNumber {
            digits.append(stripped[i])
            i = stripped.index(after: i)
        }
        guard !digits.isEmpty, let number = Int(digits) else { return nil }
        guard i < stripped.endIndex, stripped[i] == "." else { return nil }
        let afterDot = stripped.index(after: i)
        guard afterDot < stripped.endIndex, stripped[afterDot] == " " else { return nil }
        let text = String(stripped[stripped.index(after: afterDot)...])
        return (number, text)
    }

    private static func renderInline(_ text: String, baseFont: NSFont, paragraph: NSParagraphStyle) -> NSAttributedString {
        let bold = NSFont.systemFont(ofSize: baseFont.pointSize, weight: .bold)
        let italic = italicVariant(of: baseFont)
        let mono = NSFont.monospacedSystemFont(ofSize: baseFont.pointSize - 1, weight: .regular)
        let baseAttrs: [NSAttributedString.Key: Any] = [
            .font: baseFont,
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: paragraph
        ]
        let codeBg = NSColor.labelColor.withAlphaComponent(0.08)

        let result = NSMutableAttributedString()
        let chars = Array(text)
        var i = 0
        var buffer = ""

        func flush() {
            if !buffer.isEmpty {
                result.append(NSAttributedString(string: buffer, attributes: baseAttrs))
                buffer = ""
            }
        }

        while i < chars.count {
            // **bold**
            if chars[i] == "*", i + 1 < chars.count, chars[i + 1] == "*",
               let end = findClosing(["*", "*"], in: chars, from: i + 2) {
                flush()
                let inner = String(chars[(i + 2)..<end])
                var attrs = baseAttrs
                attrs[.font] = bold
                result.append(NSAttributedString(string: inner, attributes: attrs))
                i = end + 2
                continue
            }
            // *italic*
            if chars[i] == "*", i + 1 < chars.count, chars[i + 1] != "*",
               let end = findClosing(["*"], in: chars, from: i + 1),
               end == i + 1 || chars[end - 1] != " " {
                flush()
                let inner = String(chars[(i + 1)..<end])
                var attrs = baseAttrs
                attrs[.font] = italic
                result.append(NSAttributedString(string: inner, attributes: attrs))
                i = end + 1
                continue
            }
            // `code`
            if chars[i] == "`", let end = findClosing(["`"], in: chars, from: i + 1) {
                flush()
                let inner = String(chars[(i + 1)..<end])
                var attrs = baseAttrs
                attrs[.font] = mono
                attrs[.backgroundColor] = codeBg
                result.append(NSAttributedString(string: inner, attributes: attrs))
                i = end + 1
                continue
            }
            buffer.append(chars[i])
            i += 1
        }
        flush()
        return result
    }

    private static func findClosing(_ marker: [Character], in chars: [Character], from: Int) -> Int? {
        guard !marker.isEmpty, from <= chars.count - marker.count else { return nil }
        var i = from
        while i <= chars.count - marker.count {
            var match = true
            for k in 0..<marker.count where chars[i + k] != marker[k] { match = false; break }
            if match { return i }
            i += 1
        }
        return nil
    }

    private static func italicVariant(of font: NSFont) -> NSFont {
        let descriptor = font.fontDescriptor.withSymbolicTraits(.italic)
        return NSFont(descriptor: descriptor, size: font.pointSize) ?? font
    }
}
