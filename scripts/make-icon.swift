#!/usr/bin/env swift
// Writes the app icon (an Icon Composer document) and the menu-bar icon. Run from the repo root:
//   swift scripts/make-icon.swift
// AppIcon.icon can also be opened and tweaked in Icon Composer (Xcode › Open Developer Tool).
import AppKit

let resources = URL(fileURLWithPath: "Sources/OmniKeys/Resources")
let fileManager = FileManager.default

// MARK: - App icon: Icon Composer document

// Layers are flat shapes on the full 1024-point canvas; macOS adds the glass, lighting and depth, and derives the
// Dark, Clear and Tinted appearances. Xcode renders plain PNGs from it for macOS 14–25.

/// The ✦ Hyper mark: a four-point star with curved sides, centred on (cx, cy).
func starPath(cx: Double, cy: Double, radius r: Double) -> String {
    let k = r * 0.2 // how far the curves pull towards the centre
    func p(_ x: Double, _ y: Double) -> String {
        String(format: "%.1f,%.1f", cx + x, cy + y)
    }
    return "M\(p(0, -r)) C\(p(k, -k)) \(p(k, -k)) \(p(r, 0)) C\(p(k, k)) \(p(k, k)) \(p(0, r)) "
        + "C\(p(-k, k)) \(p(-k, k)) \(p(-r, 0)) C\(p(-k, -k)) \(p(-k, -k)) \(p(0, -r)) Z"
}

func svg(_ body: String) -> String {
    """
    <svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
    \(body)
    </svg>

    """
}

func capRect(x: Double, y: Double, side: Double, fill: String) -> String {
    let radius = side * 0.22
    return "<rect x=\"\(x)\" y=\"\(y)\" width=\"\(side)\" height=\"\(side)\" rx=\"\(radius)\" fill=\"\(fill)\"/>"
}

let mainCap = 600.0
let layers: [(name: String, svg: String)] = [
    ("Hyper", svg("<path d=\"\(starPath(cx: 512, cy: 512, radius: 205))\" fill=\"#3B6FF5\"/>")),
    ("Key cap", svg(capRect(x: 512 - mainCap / 2, y: 512 - mainCap / 2, side: mainCap, fill: "#FFFFFF"))),
]

let iconURL = resources.appendingPathComponent("AppIcon.icon")
let assetsURL = iconURL.appendingPathComponent("Assets")
try? fileManager.removeItem(at: iconURL)
try fileManager.createDirectory(at: assetsURL, withIntermediateDirectories: true)
for layer in layers {
    try layer.svg.write(to: assetsURL.appendingPathComponent("\(layer.name).svg"), atomically: true, encoding: .utf8)
}

/// One group per layer so each gets its own depth; listed top first.
let groups: [[String: Any]] = [
    [
        "name": "Hyper",
        "layers": [["name": "Hyper", "image-name": "Hyper.svg", "glass": false]],
        "shadow": ["kind": "layer-color", "opacity": 0.35],
    ],
    [
        "name": "Key cap",
        "layers": [["name": "Key cap", "image-name": "Key cap.svg", "glass": true]],
        "shadow": ["kind": "neutral", "opacity": 0.6],
    ],
]
let document: [String: Any] = [
    "fill": ["automatic-gradient": "extended-srgb:0.23137,0.27451,0.86275,1.00000"],
    "groups": groups,
    "supported-platforms": ["squares": "shared"],
]
try JSONSerialization.data(withJSONObject: document, options: [.prettyPrinted, .sortedKeys])
    .write(to: iconURL.appendingPathComponent("icon.json"))
print("Wrote \(iconURL.path)")

// MARK: - Menu-bar icon: template PDF

// An 18-point key cap outline with a solid ✦; a template image, so macOS colours it for the menu bar.
let catalog = resources.appendingPathComponent("Assets.xcassets")
let imageSet = catalog.appendingPathComponent("MenuBarIcon.imageset")
try fileManager.createDirectory(at: imageSet, withIntermediateDirectories: true)

func menuBarPDF() throws -> Data {
    let side = 18.0
    let data = NSMutableData()
    var box = CGRect(x: 0, y: 0, width: side, height: side)
    guard let consumer = CGDataConsumer(data: data as CFMutableData),
          let context = CGContext(consumer: consumer, mediaBox: &box, nil)
    else { throw CocoaError(.fileWriteUnknown) }
    context.beginPDFPage(nil)
    context.setFillColor(NSColor.black.cgColor)
    context.setStrokeColor(NSColor.black.cgColor)
    let line = 1.5
    let cap = CGRect(x: 1.5, y: 1.5, width: side - 3, height: side - 3)
    context.setLineWidth(line)
    context.addPath(CGPath(roundedRect: cap, cornerWidth: 4, cornerHeight: 4, transform: nil))
    context.strokePath()
    let star = NSBezierPath()
    let (cx, cy, r) = (side / 2, side / 2, 4.6)
    let k = r * 0.2
    star.move(to: NSPoint(x: cx, y: cy + r))
    for (end, control) in [
        (NSPoint(x: cx + r, y: cy), NSPoint(x: cx + k, y: cy + k)),
        (NSPoint(x: cx, y: cy - r), NSPoint(x: cx + k, y: cy - k)),
        (NSPoint(x: cx - r, y: cy), NSPoint(x: cx - k, y: cy - k)),
        (NSPoint(x: cx, y: cy + r), NSPoint(x: cx - k, y: cy + k)),
    ] {
        star.curve(to: end, controlPoint1: control, controlPoint2: control)
    }
    context.addPath(star.cgPath)
    context.fillPath()
    context.endPDFPage()
    context.closePDF()
    return data as Data
}

try menuBarPDF().write(to: imageSet.appendingPathComponent("MenuBarIcon.pdf"))
let imageSetContents: [String: Any] = [
    "images": [["idiom": "universal", "filename": "MenuBarIcon.pdf"]],
    "info": ["author": "xcode", "version": 1],
    "properties": ["template-rendering-intent": "template", "preserves-vector-representation": true],
]
try JSONSerialization.data(withJSONObject: imageSetContents, options: [.prettyPrinted, .sortedKeys])
    .write(to: imageSet.appendingPathComponent("Contents.json"))
print("Wrote \(imageSet.path)")
