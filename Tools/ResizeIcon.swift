#!/usr/bin/env swift
import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Args: [input-path] [output-path] [new-inset-percent]
//   new-inset-percent is the margin on each side as a fraction of canvas size.
//   Examples: 0.025 → 95% fill, 0.05 → 90% fill, 0.0977 → macOS template (80%).
let args = CommandLine.arguments
let inputPath  = args.count > 1 ? args[1] : "Tools/source_icon.png"
let outputPath = args.count > 2 ? args[2] : inputPath
let newInsetPct: Double = args.count > 3 ? (Double(args[3]) ?? 0.025) : 0.025

guard let nsImage = NSImage(contentsOfFile: inputPath),
      let cg = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    FileHandle.standardError.write(Data("Failed to load \(inputPath)\n".utf8))
    exit(1)
}

let pixels = cg.width
let S = CGFloat(pixels)

// Assumes the current source has its squircle at macOS template position (inset 9.77%).
let currentInset = S * 0.0977
let newInset = S * CGFloat(newInsetPct)
let scale = (S - 2 * newInset) / (S - 2 * currentInset)
let destWidth = S * scale
let destOffset = newInset - currentInset * scale

let cs = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(data: nil, width: pixels, height: pixels,
                           bitsPerComponent: 8, bytesPerRow: 0,
                           space: cs,
                           bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { exit(1) }
ctx.interpolationQuality = .high
ctx.draw(cg, in: CGRect(x: destOffset, y: destOffset, width: destWidth, height: destWidth))

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

let fillPct = Int((1 - 2 * newInsetPct) * 100)
print("✓ Resized squircle to \(fillPct)% of canvas (margin \(Int(newInset))px each side) → \(outputPath)")
