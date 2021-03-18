#if os(macOS)
import Cocoa

extension Snapshotting where Value == CALayer, Format == NSImage {
  /// A snapshot strategy for comparing layers based on pixel equality.
  public static var image: Snapshotting {
    return .image(precision: 1)
  }

  /// A snapshot strategy for comparing layers based on pixel equality.
  ///
  /// - Parameter precision: The percentage of pixels that must match.
  public static func image(precision: Float) -> Snapshotting {
    return SimplySnapshotting.image(
      precision: precision
    ).asyncPullback(
      Formatting.image.format
    )
  }
}

extension Formatting where Value == CALayer, Format == NSImage {
  /// A format strategy for converting layers to images.
  public static var image: Formatting {
    return Formatting(format: { layer in
      let image = NSImage(size: layer.bounds.size)
      image.lockFocus()
      let context = NSGraphicsContext.current!.cgContext
      layer.setNeedsLayout()
      layer.layoutIfNeeded()
      layer.render(in: context)
      image.unlockFocus()
      return image
    })
  }
}

#elseif os(iOS) || os(tvOS)
import UIKit

extension Snapshotting where Value == CALayer, Format == UIImage {
  /// A snapshot strategy for comparing layers based on pixel equality.
  public static var image: Snapshotting {
    return .image()
  }

  /// A snapshot strategy for comparing layers based on pixel equality.
  ///
  /// - Parameter precision: The percentage of pixels that must match.
  public static func image(precision: Float = 1, traits: UITraitCollection = .init() ) -> Snapshotting {
    return SimplySnapshotting.image(
      precision: precision
    ).asyncPullback(
      Formatting.image(traits: traits).format
    )
  }
}

extension Formatting where Value == CALayer, Format == UIImage {
  /// A format strategy for converting layers to images.
  public static func image(traits: UITraitCollection = .init()) -> Formatting {
    Self(format: { layer in
      renderer(bounds: layer.bounds, for: traits).image { ctx in
        layer.setNeedsLayout()
        layer.layoutIfNeeded()
        layer.render(in: ctx.cgContext)
      }
    })
  }
}
#endif
