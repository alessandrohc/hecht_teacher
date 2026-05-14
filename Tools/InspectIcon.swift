#!/usr/bin/env swift
import AppKit

let path = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Tools/source_icon.png"

guard let nsImage = NSImage(contentsOfFile: path),
      let cg = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    print("Failed to load \(path)"); exit(1)
}

let w = cg.width
let h = cg.height
let cs = CGColorSpaceCreateDeviceRGB()
let bytesPerRow = w * 4
var pixels = [UInt8](repeating: 0, count: bytesPerRow * h)
guard let ctx = CGContext(data: &pixels, width: w, height: h,
                           bitsPerComponent: 8, bytesPerRow: bytesPerRow,
                           space: cs,
                           bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { exit(1) }
ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))

func sample(_ x: Int, _ y: Int) -> String {
    let yy = h - 1 - y          // flip to image-coords (top-left origin)
    let i = yy * bytesPerRow + x * 4
    let r = Int(pixels[i])
    let g = Int(pixels[i + 1])
    let b = Int(pixels[i + 2])
    let a = Int(pixels[i + 3])
    return String(format: "R=%3d G=%3d B=%3d A=%3d", r, g, b, a)
}

print("Image: \(w)×\(h)")
let probes: [(String, Int, Int)] = [
    ("inside squircle, no caveman (200,200)", 200, 200),
    ("inside squircle, center (512,512)",     512, 512),
    ("top of squircle (512,180)",             512, 180),
    ("caveman body (450,580)",                450, 580),
    ("outside top-left (40,40)",              40,  40),
    ("outside top-right (980,40)",            980, 40),
]
for (label, x, y) in probes {
    print("  \(label.padding(toLength: 42, withPad: " ", startingAt: 0)) → \(sample(x, y))")
}
