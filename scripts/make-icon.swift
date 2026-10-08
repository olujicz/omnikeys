#!/usr/bin/env swift
// Draws the app icon at every macOS size into the asset catalog. Run from the repo root:
//   swift scripts/make-icon.swift
import AppKit

let catalog = URL(fileURLWithPath: "Sources/OmniKeys/Resources/Assets.xcassets")
let iconSet = catalog.appendingPathComponent("AppIcon.appiconset")
try FileManager.default.createDirectory(at: iconSet, withIntermediateDirectories: true)

func png(size: Int) throws -> Data {
    let side = CGFloat(size)
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    ) else { throw CocoaError(.fileWriteUnknown) }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    // macOS icon grid: an 824/1024 rounded square, centred.
    let inset = side * 100 / 1024
    let body = NSRect(x: inset, y: inset, width: side - 2 * inset, height: side - 2 * inset)
    let bodyPath = NSBezierPath(roundedRect: body, xRadius: side * 185 / 1024, yRadius: side * 185 / 1024)
    NSGradient(
        starting: NSColor(calibratedRed: 0.17, green: 0.19, blue: 0.25, alpha: 1),
        ending: NSColor(calibratedRed: 0.06, green: 0.07, blue: 0.10, alpha: 1)
    )?.draw(in: bodyPath, angle: -90)
    // One accent key cap with the ✦ Hyper mark.
    let cap = body.insetBy(dx: body.width * 0.21, dy: body.height * 0.21)
    let capPath = NSBezierPath(roundedRect: cap, xRadius: cap.width * 0.17, yRadius: cap.width * 0.17)
    NSColor(calibratedRed: 0.30, green: 0.55, blue: 1.0, alpha: 1).setFill()
    capPath.fill()
    let glyph = "✦" as NSString
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: cap.height * 0.56, weight: .bold),
        .foregroundColor: NSColor.white,
    ]
    let glyphSize = glyph.size(withAttributes: attributes)
    glyph.draw(
        at: NSPoint(x: cap.midX - glyphSize.width / 2, y: cap.midY - glyphSize.height / 2),
        withAttributes: attributes
    )
    NSGraphicsContext.restoreGraphicsState()
    guard let data = rep.representation(using: .png, properties: [:]) else { throw CocoaError(.fileWriteUnknown) }
    return data
}

var images: [[String: String]] = []
for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = "icon_\(points)x\(points)\(scale == 2 ? "@2x" : "").png"
        try png(size: points * scale).write(to: iconSet.appendingPathComponent(name))
        images.append(["idiom": "mac", "size": "\(points)x\(points)", "scale": "\(scale)x", "filename": name])
    }
}

let info = ["author": "xcode", "version": 1] as [String: Any]
try JSONSerialization.data(withJSONObject: ["images": images, "info": info], options: [.prettyPrinted, .sortedKeys])
    .write(to: iconSet.appendingPathComponent("Contents.json"))
try JSONSerialization.data(withJSONObject: ["info": info], options: [.prettyPrinted, .sortedKeys])
    .write(to: catalog.appendingPathComponent("Contents.json"))
print("Wrote \(images.count) icon sizes to \(iconSet.path)")
