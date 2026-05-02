import AppKit
import Foundation

enum RenderError: LocalizedError {
    case invalidArguments
    case invalidSize
    case failedToLoadImage(String)
    case failedToCreateBitmap
    case failedToEncodePng

    var errorDescription: String? {
        switch self {
        case .invalidArguments:
            return "Usage: render_svg_to_png <input.svg> <output.png> <width> <height>"
        case .invalidSize:
            return "Width and height must be positive integers."
        case .failedToLoadImage(let path):
            return "Couldn't load SVG image at \(path)."
        case .failedToCreateBitmap:
            return "Couldn't create bitmap context."
        case .failedToEncodePng:
            return "Couldn't encode PNG output."
        }
    }
}

func main() throws {
    guard CommandLine.arguments.count == 5 else {
        throw RenderError.invalidArguments
    }

    let inputPath = CommandLine.arguments[1]
    let outputPath = CommandLine.arguments[2]

    guard
        let width = Int(CommandLine.arguments[3]),
        let height = Int(CommandLine.arguments[4]),
        width > 0,
        height > 0
    else {
        throw RenderError.invalidSize
    }

    let inputURL = URL(fileURLWithPath: inputPath)
    let outputURL = URL(fileURLWithPath: outputPath)
    let renderSize = NSSize(width: width, height: height)

    guard let image = NSImage(contentsOf: inputURL) else {
        throw RenderError.failedToLoadImage(inputPath)
    }

    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: width,
        pixelsHigh: height,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw RenderError.failedToCreateBitmap
    }

    bitmap.size = renderSize

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    NSColor.clear.setFill()
    NSBezierPath(rect: NSRect(origin: .zero, size: renderSize)).fill()
    image.draw(
        in: NSRect(origin: .zero, size: renderSize),
        from: NSRect(origin: .zero, size: image.size),
        operation: .copy,
        fraction: 1
    )
    NSGraphicsContext.restoreGraphicsState()

    guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
        throw RenderError.failedToEncodePng
    }

    try pngData.write(to: outputURL)
}

do {
    try main()
} catch {
    fputs((error.localizedDescription + "\n"), stderr)
    exit(1)
}
