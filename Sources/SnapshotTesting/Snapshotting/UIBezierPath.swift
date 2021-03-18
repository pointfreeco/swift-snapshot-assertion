#if os(iOS) || os(tvOS)
import UIKit

extension Snapshotting where Value == UIBezierPath, Format == UIImage {
  /// A snapshot strategy for comparing bezier paths based on pixel equality.
  public static var image: Snapshotting {
    return .image()
  }

  /// A snapshot strategy for comparing bezier paths based on pixel equality.
  ///
  /// - Parameter precision: The percentage of pixels that must match.
  public static func image(precision: Float = 1, scale: CGFloat = 1) -> Snapshotting {
    return SimplySnapshotting.image(
        precision: precision
    ).asyncPullback(
      Formatting.image(scale: scale).format
    )
  }
}

extension Formatting where Value == UIBezierPath, Format == UIImage {
  /// A format strategy for converting strings to strings.
  public static func image(scale: CGFloat = 1) ->  Formatting {
    return Formatting(format: { path in
        let bounds = path.bounds
        let format: UIGraphicsImageRendererFormat
        if #available(iOS 11.0, tvOS 11.0, *) {
          format = UIGraphicsImageRendererFormat.preferred()
        } else {
          format = UIGraphicsImageRendererFormat.default()
        }
        format.scale = scale
        return UIGraphicsImageRenderer(bounds: bounds, format: format).image { ctx in
          path.fill()
        }
    })
  }
}

@available(iOS 11.0, tvOS 11.0, *)
extension Snapshotting where Value == UIBezierPath, Format == String {
  /// A snapshot strategy for comparing bezier paths based on pixel equality.
  public static var elementsDescription: Snapshotting {
    return .elementsDescription()
  }

  /// A snapshot strategy for comparing bezier paths based on pixel equality.
  ///
  /// - Parameter numberFormatter: The number formatter used for formatting points.
  public static func elementsDescription(numberFormatter: NumberFormatter? = nil) -> Snapshotting {
    Snapshotting<CGPath, String>.elementsDescription(
      numberFormatter: numberFormatter
    ).asyncPullback(
      Formatting.path.format
    )
  }
}

extension Formatting where Value == UIBezierPath, Format == CGPath {
  /// A format strategy for converting strings to strings.
  public static var path: Formatting {
    return Formatting(format: { path in
      path.cgPath
    })
  }
}
#endif
