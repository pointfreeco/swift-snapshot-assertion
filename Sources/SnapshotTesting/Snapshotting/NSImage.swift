#if os(macOS)
import Cocoa
import XCTest

extension Diffing where Value == NSImage {
  /// A pixel-diffing strategy for NSImage's which requires a 100% match.
  public static let image = Diffing.image(precision: 1)

  /// A pixel-diffing strategy for NSImage that allows customizing how precise the matching must be.
  ///
  /// - Parameter precision: A value between 0 and 1, where 1 means the images must match 100% of their pixels.
  /// - Returns: A new diffing strategy.
  public static func image(precision: Float) -> Diffing {
    return Diffing(
      toData: { Self.toData($0)! },
      fromData: { Self.fromData($0)! },
      diff: { Self.diff($0, $1, precision: precision) }
    )
  }

  public static func toData(_ image: Value) -> Data? {
    guard let cgImage = cgImageFrom(nsImage: image) else { return nil }
    let rep = NSBitmapImageRep(cgImage: cgImage)
    rep.size = image.size
    return rep.representation(using: .png, properties: [:])
  }

  public static func fromData(_ data: Data) -> Value? {
    NSImage(data: data)
  }

  public static func diff(_ old: Value, _ new: Value, precision: Float) -> (String, [XCTAttachment])? {
    return Diffing<CGImage>.diff(
      cgImageFrom(nsImage: old)!,
      cgImageFrom(nsImage: new)!,
      precision: precision
    )
  }
}

extension Snapshotting where Value == NSImage, Format == NSImage {
  /// A snapshot strategy for comparing images based on pixel equality.
  public static var image: Snapshotting {
    return .image(precision: 1)
  }

  /// A snapshot strategy for comparing images based on pixel equality.
  ///
  /// - Parameter precision: The percentage of pixels that must match.
  public static func image(precision: Float) -> Snapshotting {
    return Snapshotting(
      pathExtension: "png",
      diffing: .image(precision: precision)
    )
  }
}

internal func cgImageFrom(nsImage: NSImage) -> CGImage? {
  nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
}

#endif
