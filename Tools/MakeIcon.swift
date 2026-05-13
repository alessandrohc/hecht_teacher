#!/usr/bin/env swift
import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let outputDir = "Tools/AppIcon.iconset"
let fm = FileManager.default
try? fm.removeItem(atPath: outputDir)
try fm.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

let sizes: [(name: String, pixels: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

func makeContext(size: Int) -> CGContext? {
    return CGContext(
        data: nil,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )
}

func render(pixels: Int) -> CGImage? {
    guard let ctx = makeContext(size: pixels) else { return nil }
    let S = CGFloat(pixels)

    // Geometry: macOS Big Sur+ icon template — squircle inset ~9.7%, corner ~22%.
    let inset = S * 0.0977
    let bg = CGRect(x: inset, y: inset, width: S - 2 * inset, height: S - 2 * inset)
    let corner = bg.width * 0.225

    // 1) Background squircle with a soft drop shadow.
    let squircle = CGPath(roundedRect: bg, cornerWidth: corner, cornerHeight: corner, transform: nil)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -S * 0.012),
                  blur: S * 0.025,
                  color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.25))
    ctx.addPath(squircle)
    ctx.setFillColor(CGColor(red: 0.18, green: 0.32, blue: 0.88, alpha: 1.0))
    ctx.fillPath()
    ctx.restoreGState()

    // 2) Diagonal blue gradient clipped to the squircle.
    ctx.saveGState()
    ctx.addPath(squircle)
    ctx.clip()
    let gradientColors = [
        CGColor(red: 0.31, green: 0.55, blue: 1.00, alpha: 1.0),  // top-left  : sky blue  #4F8BFF
        CGColor(red: 0.17, green: 0.31, blue: 0.88, alpha: 1.0),  // bottom-rt : deep blue #2C4FE1
    ] as CFArray
    if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                 colors: gradientColors,
                                 locations: [0, 1]) {
        ctx.drawLinearGradient(gradient,
                               start: CGPoint(x: bg.minX, y: bg.maxY),
                               end:   CGPoint(x: bg.maxX, y: bg.minY),
                               options: [])
    }
    // Subtle top highlight
    let highlightColors = [
        CGColor(red: 1, green: 1, blue: 1, alpha: 0.18),
        CGColor(red: 1, green: 1, blue: 1, alpha: 0.0),
    ] as CFArray
    if let glossy = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                               colors: highlightColors,
                               locations: [0, 1]) {
        ctx.drawLinearGradient(glossy,
                               start: CGPoint(x: bg.midX, y: bg.maxY),
                               end:   CGPoint(x: bg.midX, y: bg.midY),
                               options: [])
    }
    ctx.restoreGState()

    // 3) White speech bubble with a small tail at bottom-left.
    let pad = bg.width * 0.16
    let bubbleRect = CGRect(
        x: bg.minX + pad,
        y: bg.minY + pad * 1.35,
        width: bg.width - 2 * pad,
        height: bg.height - 2 * pad
    )
    let bRadius = bubbleRect.height * 0.30

    let bubble = CGMutablePath()
    bubble.addRoundedRect(in: bubbleRect, cornerWidth: bRadius, cornerHeight: bRadius)

    // Tail: small triangle pointing down-left, attached to the bubble's bottom edge.
    let tailW = S * 0.085
    let tailH = S * 0.085
    let tailX = bubbleRect.minX + bubbleRect.width * 0.22
    let tailY = bubbleRect.minY
    bubble.move(to: CGPoint(x: tailX, y: tailY))
    bubble.addLine(to: CGPoint(x: tailX - tailW * 0.35, y: tailY - tailH))
    bubble.addLine(to: CGPoint(x: tailX + tailW, y: tailY))
    bubble.closeSubpath()

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -S * 0.006),
                  blur: S * 0.012,
                  color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.22))
    ctx.addPath(bubble)
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1.0))
    ctx.fillPath()
    ctx.restoreGState()

    // 4) "Aa" text inside the bubble.
    let nsCtx = NSGraphicsContext(cgContext: ctx, flipped: false)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = nsCtx

    let fontSize = S * 0.34
    let font = NSFont.systemFont(ofSize: fontSize, weight: .heavy)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor(srgbRed: 0.12, green: 0.23, blue: 0.55, alpha: 1.0),
        .kern: -fontSize * 0.02,
    ]
    let text = NSAttributedString(string: "Aa", attributes: attrs)
    let textSize = text.size()
    let textOrigin = CGPoint(
        x: bubbleRect.midX - textSize.width / 2,
        y: bubbleRect.midY - textSize.height / 2 + fontSize * 0.04
    )
    text.draw(at: textOrigin)

    NSGraphicsContext.restoreGraphicsState()

    return ctx.makeImage()
}

func savePNG(_ image: CGImage, to path: String) {
    let url = URL(fileURLWithPath: path)
    let utType: CFString
    if #available(macOS 11, *) {
        utType = UTType.png.identifier as CFString
    } else {
        utType = "public.png" as CFString
    }
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, utType, 1, nil) else {
        FileHandle.standardError.write(Data("Failed to create destination for \(path)\n".utf8))
        exit(1)
    }
    CGImageDestinationAddImage(dest, image, nil)
    if !CGImageDestinationFinalize(dest) {
        FileHandle.standardError.write(Data("Failed to write \(path)\n".utf8))
        exit(1)
    }
    print("✓ \(path)")
}

for entry in sizes {
    guard let img = render(pixels: entry.pixels) else {
        FileHandle.standardError.write(Data("Render failed for \(entry.name)\n".utf8))
        exit(1)
    }
    savePNG(img, to: "\(outputDir)/\(entry.name)")
}

print("Done. Run: iconutil -c icns -o Resources/AppIcon.icns \(outputDir)")
