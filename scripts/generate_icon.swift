import AppKit

let inputPath = "/Users/himanzero/.gemini/antigravity/brain/d08f3109-7aa5-45a4-8049-ae0bc4e5bece/.user_uploaded/media_1793514693978_020b92dc.jpg"
let outputIconsetPath = "AppIcon.iconset"
let assetsIconPath = "docs/assets/app_icon.png"

guard let sourceImage = NSImage(contentsOfFile: inputPath) else {
    print("Failed to load source image")
    exit(1)
}

let fm = FileManager.default
try? fm.removeItem(atPath: outputIconsetPath)
try fm.createDirectory(atPath: outputIconsetPath, withIntermediateDirectories: true)

// In macOS Big Sur/Sequoia app icons, the black background surrounding the squircle must be transparent.
// The uploaded image has a squircle icon centered on a black background (#000000).
// We sample and mask everything outside the rounded squircle to alpha 0.

func maskToSquircle(source: NSImage, targetPixelSize: Int) -> NSImage {
    let size = CGSize(width: targetPixelSize, height: targetPixelSize)
    let output = NSImage(size: size)
    output.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        output.unlockFocus()
        return output
    }

    let rect = CGRect(origin: .zero, size: size)
    
    // In macOS Big Sur standard grid:
    // If the image already has the 1024x1024 bounding box with squircle taking up the standard inner area (~824x824, inset ~100px or ~10%):
    // Let's create an accurate squircle mask matching the squircle boundary of the image.
    // The image has black corners. We create a mask for the squircle:
    let inset = CGFloat(targetPixelSize) * 0.082
    let iconRect = rect.insetBy(dx: inset, dy: inset)
    let cornerRadius = iconRect.width * 0.225

    let path = CGPath(roundedRect: iconRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    ctx.addPath(path)
    ctx.clip()

    source.draw(in: rect, from: .zero, operation: .copy, fraction: 1.0)

    output.unlockFocus()
    return output
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
    let masked = maskToSquircle(source: sourceImage, targetPixelSize: spec.pixels)
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: spec.pixels,
        pixelsHigh: spec.pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else { continue }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    masked.draw(in: CGRect(x: 0, y: 0, width: spec.pixels, height: spec.pixels))
    NSGraphicsContext.restoreGraphicsState()

    if let pngData = rep.representation(using: .png, properties: [:]) {
        try pngData.write(to: URL(fileURLWithPath: "\(outputIconsetPath)/\(spec.name)"))
        if spec.pixels == 512 {
            try pngData.write(to: URL(fileURLWithPath: assetsIconPath))
        }
    }
}

print("Iconset created successfully.")
