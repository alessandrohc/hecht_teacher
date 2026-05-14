#!/usr/bin/env swift
import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Args: [original-path] [output-path] [zoom] [inset-percent]
//   zoom: how much to scale the original so its clean cream interior covers the new canvas
//         1.27 places the user's antialiased squircle edge ~14 px outside the new canvas, safe.
//   inset-percent: margin of the new squircle clip (0.0 = full-canvas fill).
let args = CommandLine.arguments
let inputPath  = args.count > 1 ? args[1] : "Tools/source_icon_original.png"
let outputPath = args.count > 2 ? args[2] : "Tools/source_icon.png"
let zoom: CGFloat = args.count > 3 ? (CGFloat(Double(args[3]) ?? 1.27)) : 1.27
let insetPct: Double = args.count > 4 ? (Double(args[4]) ?? 0.0) : 0.0

guard let nsImage = NSImage(contentsOfFile: inputPath),
      let cg = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    FileHandle.standardError.write(Data("Failed to load \(inputPath)\n".utf8))
    exit(1)
}

let canvas = 1024
let S = CGFloat(canvas)
let scaledSize = S * zoom
let offset = (S - scaledSize) / 2

let cs = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(data: nil, width: canvas, height: canvas,
                           bitsPerComponent: 8, bytesPerRow: 0,
                           space: cs,
                           bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { exit(1) }
ctx.interpolationQuality = .high

let inset = S * CGFloat(insetPct)
let rect = CGRect(x: inset, y: inset, width: S - 2 * inset, height: S - 2 * inset)
let corner = rect.width * 0.225
let squircle = CGPath(roundedRect: rect, cornerWidth: corner, cornerHeight: corner, transform: nil)

ctx.addPath(squircle)
ctx.clip()
ctx.draw(cg, in: CGRect(x: offset, y: offset, width: scaledSize, height: scaledSize))

guard let output = ctx.makeImage() else { exit(1) }
let url = URL(fileURLWithPath: outputPath)
guard let dest = CGImageDestinationCreateWithURL(
    url as CFURL,
    UTType.png.identifier as CFString,
    1,
    nil
) else { exit(1) }
CGImageDestinationAddImage(dest, output, nil)
guard CGImageDestinationFinalize(dest) else { exit(1) }

let fillPct = Int((1 - 2 * insetPct) * 100)
print("✓ Rebuilt icon (\(fillPct)% canvas fill, zoom \(zoom)) → \(outputPath)")
