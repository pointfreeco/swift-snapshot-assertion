#if os(iOS) || os(tvOS)
import UIKit
import XCTest

extension Diffing where Value == UIImage {
  /// A pixel-diffing strategy for UIImage's which requires a 100% match.
  public static let image = Diffing.image(precision: 1)

  /// A pixel-diffing strategy for UIImage that allows customizing how precise the matching must be.
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
    image.pngData()
  }

  public static func fromData(_ data: Data) -> Value? {
    UIImage(data: data, scale: UIScreen.main.scale)
  }

  public static func diff(_ old: Value, _ new: Value, precision: Float) -> (String, [XCTAttachment])? {
    return Diffing<CGImage>.diff(
      old.cgImage!,
      new.cgImage!,
      precision: precision
    )
  }
}

extension Snapshotting where Value == UIImage, Format == UIImage {
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
#endif
