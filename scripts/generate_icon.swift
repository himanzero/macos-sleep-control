import AppKit

let outputIconsetPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".build/AppIcon.iconset"
let assetsIconPath = "docs/assets/app_icon.png"
let heroCatPath = "Resources/hero_cat_awake@2x.png"

guard let catImage = NSImage(contentsOfFile: heroCatPath) else {
    fputs("Failed to load hero cat image at \(heroCatPath)\n", stderr)
    exit(1)
}

let fm = FileManager.default
try? fm.removeItem(atPath: outputIconsetPath)
try fm.createDirectory(atPath: outputIconsetPath, withIntermediateDirectories: true)

let alabaster = CGColor(srgbRed: 0xF5 / 255.0, green: 0xF1 / 255.0, blue: 0xE8 / 255.0, alpha: 1.0)
let obsidian = CGColor(srgbRed: 0x11 / 255.0, green: 0x12 / 255.0, blue: 0x16 / 255.0, alpha: 1.0)
let ink = CGColor(srgbRed: 0x1A / 255.0, green: 0x19 / 255.0, blue: 0x17 / 255.0, alpha: 1.0)
let inkSoft = CGColor(srgbRed: 0x1A / 255.0, green: 0x19 / 255.0, blue: 0x17 / 255.0, alpha: 0.22)
let amber = CGColor(srgbRed: 0xE5 / 255.0, green: 0x9A / 255.0, blue: 0x3C / 255.0, alpha: 1.0)

/// Clean crescent moon rendered via CGContext transparency layer + .clear blend mode
func drawSmoothCrescent(center: CGPoint, radius: CGFloat, color: CGColor, ctx: CGContext) {
    ctx.saveGState()
    ctx.beginTransparencyLayer(auxiliaryInfo: nil)
    ctx.setFillColor(color)
    ctx.fillEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
    let cutoutCenter = CGPoint(x: center.x + radius * 0.42, y: center.y + radius * 0.26)
    let cutoutR = radius * 0.84
    ctx.setBlendMode(.clear)
    ctx.fillEllipse(in: CGRect(x: cutoutCenter.x - cutoutR, y: cutoutCenter.y - cutoutR, width: cutoutR * 2, height: cutoutR * 2))
    ctx.endTransparencyLayer()
    ctx.restoreGState()
}

/// Editorial Power Mark (open Espresso Ink ring + Amber vertical bar)
func drawPowerEmblem(center: CGPoint, radius: CGFloat, strokeWidth: CGFloat, ctx: CGContext) {
    ctx.saveGState()
    ctx.setLineCap(.round)
    ctx.setStrokeColor(ink)
    ctx.setLineWidth(strokeWidth)
    ctx.addArc(center: center, radius: radius, startAngle: .pi * 0.68, endAngle: .pi * 0.32, clockwise: false)
    ctx.strokePath()

    ctx.setStrokeColor(amber)
    ctx.setLineWidth(strokeWidth * 1.1)
    ctx.move(to: CGPoint(x: center.x, y: center.y + radius * 0.05))
    ctx.addLine(to: CGPoint(x: center.x, y: center.y + radius * 1.15))
    ctx.strokePath()
    ctx.restoreGState()
}

/// Renders the Editorial Day/Night Split App Icon:
/// - Left half: Warm Alabaster (#F5F1E8) with Power emblem in top-left
/// - Right half: Obsidian Velvet (#111216) with Amber Crescent Moon in top-right
/// - Center: Sharp Couture Cat (Resources/hero_cat_awake@2x.png) straddling the chiaroscuro split
func renderEditorialIcon(cat: NSImage, targetPixelSize: Int) -> NSBitmapImageRep? {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: targetPixelSize,
        pixelsHigh: targetPixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else { return nil }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        NSGraphicsContext.restoreGraphicsState()
        return nil
    }

    NSGraphicsContext.current?.imageInterpolation = .high
    let s = CGFloat(targetPixelSize)
    let rect = CGRect(x: 0, y: 0, width: s, height: s)

    let inset = s * 0.082
    let iconRect = rect.insetBy(dx: inset, dy: inset)
    let cornerRadius = iconRect.width * 0.225
    let squirclePath = CGPath(
        roundedRect: iconRect,
        cornerWidth: cornerRadius,
        cornerHeight: cornerRadius,
        transform: nil
    )

    ctx.saveGState()
    ctx.addPath(squirclePath)
    ctx.clip()

    // Left half: Warm Alabaster (#F5F1E8)
    ctx.setFillColor(alabaster)
    ctx.fill(iconRect)

    // Right half: Obsidian Velvet (#111216)
    let rightHalf = CGRect(x: s * 0.5, y: iconRect.minY, width: iconRect.width * 0.5 + 2, height: iconRect.height)
    ctx.setFillColor(obsidian)
    ctx.fill(rightHalf)

    // Centered Couture Cat straddling the day/night split
    let catAspect = cat.size.width / max(cat.size.height, 1)
    let targetCatHeight = iconRect.height * 0.80
    let targetCatWidth = targetCatHeight * catAspect
    let catRect = CGRect(
        x: (s - targetCatWidth) * 0.5,
        y: iconRect.minY + iconRect.height * 0.08,
        width: targetCatWidth,
        height: targetCatHeight
    )
    cat.draw(in: catRect, from: .zero, operation: .sourceOver, fraction: 1.0)

    // Top-left Power emblem & Top-right Amber Crescent Moon (cleanly legible at >= 32px)
    if targetPixelSize >= 32 {
        drawPowerEmblem(
            center: CGPoint(
                x: iconRect.minX + iconRect.width * 0.165,
                y: iconRect.maxY - iconRect.height * 0.17
            ),
            radius: iconRect.width * 0.056,
            strokeWidth: max(1.6, iconRect.width * 0.015),
            ctx: ctx
        )

        drawSmoothCrescent(
            center: CGPoint(
                x: iconRect.maxX - iconRect.width * 0.165,
                y: iconRect.maxY - iconRect.height * 0.165
            ),
            radius: iconRect.width * 0.060,
            color: amber,
            ctx: ctx
        )
    }

    ctx.restoreGState()

    // Crisp hairline border around squircle
    ctx.saveGState()
    let borderWidth = max(1.0, s * 0.004)
    let borderRect = iconRect.insetBy(dx: borderWidth * 0.5, dy: borderWidth * 0.5)
    let borderPath = CGPath(
        roundedRect: borderRect,
        cornerWidth: max(0, cornerRadius - borderWidth * 0.5),
        cornerHeight: max(0, cornerRadius - borderWidth * 0.5),
        transform: nil
    )
    ctx.addPath(borderPath)
    ctx.setStrokeColor(inkSoft)
    ctx.setLineWidth(borderWidth)
    ctx.strokePath()
    ctx.restoreGState()

    NSGraphicsContext.restoreGraphicsState()
    return rep
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
    guard let rep = renderEditorialIcon(cat: catImage, targetPixelSize: spec.pixels),
          let pngData = rep.representation(using: .png, properties: [:]) else {
        fputs("Failed to render icon size \(spec.pixels)\n", stderr)
        exit(1)
    }
    try pngData.write(to: URL(fileURLWithPath: "\(outputIconsetPath)/\(spec.name)"))
    if spec.pixels == 512 {
        try pngData.write(to: URL(fileURLWithPath: assetsIconPath))
    }
}

print("Editorial AppIcon iconset created at \(outputIconsetPath) and \(assetsIconPath).")
