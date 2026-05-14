#!/usr/bin/env swift
import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let inputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Tools/source_icon.png"
let outputPath = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "Tools/source_icon.png"

let backupPath = "Tools/source_icon_original.png"
if !FileManager.default.fileExists(atPath: backupPath) {
    try? FileManager.default.copyItem(atPath: inputPath, toPath: backupPath)
    print("Backed up original to \(backupPath)")
}

guard let nsImage = NSImage(contentsOfFile: inputPath),
      let cg = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    FileHandle.standardError.write(Data("Failed to load \(inputPath)\n".utf8))
    exit(1)
}

let pixels = cg.width
let S = CGFloat(pixels)

let cs = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(data: nil, width: pixels, height: pixels,
                           bitsPerComponent: 8, bytesPerRow: 0,
                           space: cs,
                           bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { exit(1) }

let inset = S * 0.0977
let rect = CGRect(x: inset, y: inset, width: S - 2 * inset, height: S - 2 * inset)
let corner = rect.width * 0.225
let squircle = CGPath(roundedRect: rect, cornerWidth: corner, cornerHeight: corner, transform: nil)

ctx.addPath(squircle)
ctx.clip()
ctx.draw(cg, in: CGRect(x: 0, y: 0, width: pixels, height: pixels))

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
print("✓ Cleaned squircle, real transparency outside written to \(outputPath)")
