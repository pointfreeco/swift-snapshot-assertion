#if os(macOS)
import Cocoa

extension Snapshotting where Value == NSViewController, Format == NSImage {
  /// A snapshot strategy for comparing view controller views based on pixel equality.
  public static var image: Snapshotting {
    return .image()
  }

  /// A snapshot strategy for comparing view controller views based on pixel equality.
  ///
  /// - Parameters:
  ///   - precision: The percentage of pixels that must match.
  ///   - size: A view size override.
  public static func image(precision: Float = 1, size: CGSize? = nil) -> Snapshotting {
    return Snapshotting<NSView, NSImage>.image(
        precision: precision,
        size: size
    ).asyncPullback(
      Formatting<NSViewController, NSView>.image.format
    )
  }
}

extension Snapshotting where Value == NSViewController, Format == String {
  /// A snapshot strategy for comparing view controller views based on a recursive description of their properties and hierarchies.
  public static var recursiveDescription: Snapshotting {
    return Snapshotting<NSView, String>.recursiveDescription.asyncPullback(
        Formatting<NSViewController, NSView>.image.format
    )
  }
}

extension Formatting where Value == NSViewController, Format == NSView {
  /// A format strategy for converting layers to images.
  public static var image: Formatting {
    Self(format: { $0.view })
  }
}

extension Formatting where Value == NSViewController, Format == NSImage {
  /// A format strategy for converting layers to images.
  public static func image(size: CGSize? = nil) -> Formatting {
    Formatting<NSView, NSImage>.image(
      size: size
    ).asyncPullback(
      Formatting<NSViewController, NSView>.image.format
    )
  }
}
#endif
