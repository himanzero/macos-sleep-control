#!/usr/bin/env swift
import AppKit

/// Generates modern macOS Big Sur / Sequoia style squircle application icon set (.iconset) using AppKit and CoreGraphics.
let args = CommandLine.arguments
let outputIconsetPath = args.count > 1 ? args[1] : "AppIcon.iconset"

let fileManager = FileManager.default
try? fileManager.removeItem(atPath: outputIconsetPath)
try fileManager.createDirectory(atPath: outputIconsetPath, withIntermediateDirectories: true)

func renderIcon(size: Int) -> NSImage {
    let cgSize = CGSize(width: size, height: size)
    let image = NSImage(size: cgSize)
    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let rect = CGRect(origin: .zero, size: cgSize)
    let inset = CGFloat(size) * 0.08
    let iconRect = rect.insetBy(dx: inset, dy: inset)
    let cornerRadius = iconRect.width * 0.225

    // 1. Draw rounded squircle base with gradient (deep midnight navy to warm amber-purple)
    ctx.saveGState()
    let path = CGPath(roundedRect: iconRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    ctx.addPath(path)
    ctx.clip()

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bgColors: [CGColor] = [
        CGColor(red: 0.11, green: 0.13, blue: 0.24, alpha: 1.0),
        CGColor(red: 0.20, green: 0.16, blue: 0.36, alpha: 1.0),
        CGColor(red: 0.95, green: 0.48, blue: 0.16, alpha: 1.0)
    ]
    let locations: [CGFloat] = [0.0, 0.55, 1.0]
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: bgColors as CFArray, locations: locations) {
        ctx.drawLinearGradient(
            gradient,
            start: CGPoint(x: iconRect.minX, y: iconRect.maxY),
            end: CGPoint(x: iconRect.maxX, y: iconRect.minY),
            options: []
        )
    }

    // 2. Radial ambient center highlight
    let glowColors: [CGColor] = [
        CGColor(red: 1.0, green: 0.72, blue: 0.28, alpha: 0.45),
        CGColor(red: 1.0, green: 0.72, blue: 0.28, alpha: 0.0)
    ]
    if let radial = CGGradient(colorsSpace: colorSpace, colors: glowColors as CFArray, locations: [0.0, 1.0]) {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        ctx.drawRadialGradient(
            radial,
            startCenter: center,
            startRadius: 0,
            endCenter: center,
            endRadius: iconRect.width * 0.48,
            options: []
        )
    }

    // 3. Inner glass stroke
    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.28))
    ctx.setLineWidth(max(1.5, CGFloat(size) * 0.015))
    ctx.addPath(path)
    ctx.strokePath()
    ctx.restoreGState()

    // 4. Draw center SF Symbol icon
    let pointSize = CGFloat(size) * 0.42
    let config = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .bold)
    if let symbol = NSImage(systemSymbolName: "cup.and.saucer.fill", accessibilityDescription: nil)?.withSymbolConfiguration(config) {
        let symSize = symbol.size
        let symRect = CGRect(
            x: (cgSize.width - symSize.width) / 2.0,
            y: (cgSize.height - symSize.height) / 2.0,
            width: symSize.width,
            height: symSize.height
        )

        // Render white symbol with slight contrast
        let tinted = NSImage(size: symSize)
        tinted.lockFocus()
        NSColor.white.set()
        let drawRect = CGRect(origin: .zero, size: symSize)
        symbol.draw(in: drawRect)
        drawRect.fill(using: .sourceAtop)
        tinted.unlockFocus()

        tinted.draw(in: symRect)
    }

    image.unlockFocus()
    return image
}

func savePNG(_ image: NSImage, to path: String, pixelSize: Int) throws {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else { return }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(in: CGRect(x: 0, y: 0, width: pixelSize, height: pixelSize))
    NSGraphicsContext.restoreGraphicsState()

    if let pngData = rep.representation(using: .png, properties: [:]) {
        try pngData.write(to: URL(fileURLWithPath: path))
    }
}

let iconSpecs: [(name: String, pixels: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for spec in iconSpecs {
    let img = renderIcon(size: spec.pixels)
    let filePath = "\(outputIconsetPath)/\(spec.name)"
    try savePNG(img, to: filePath, pixelSize: spec.pixels)
}
