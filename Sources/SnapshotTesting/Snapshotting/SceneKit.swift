#if os(iOS) || os(macOS) || os(tvOS)
import SceneKit
#if os(macOS)
import Cocoa
#elseif os(iOS) || os(tvOS)
import UIKit
#endif

#if os(macOS)
extension Snapshotting where Value == SCNScene, Format == NSImage {
  /// A snapshot strategy for comparing SceneKit scenes based on pixel equality.
  ///
  /// - Parameters:
  ///   - precision: The percentage of pixels that must match.
  ///   - size: The size of the scene.
  public static func image(precision: Float = 1, size: CGSize) -> Snapshotting {
    return Snapshotting<NSView, NSImage>.image(
      precision: precision
    ).asyncPullback(
      Formatting<SCNScene, NSView>.image(
        size: size
      ).format
    )
  }
}

extension Formatting where Value == SCNScene, Format == NSView {
  /// A format strategy for converting layers to images.
  public static func image(size: CGSize) -> Formatting {
    Self(format: { scene in
        let view = SCNView(frame: .init(x: 0, y: 0, width: size.width, height: size.height))
        view.scene = scene
        return view
    })
  }
}
#elseif os(iOS) || os(tvOS)
extension Snapshotting where Value == SCNScene, Format == UIImage {
  /// A snapshot strategy for comparing SceneKit scenes based on pixel equality.
  ///
  /// - Parameters:
  ///   - precision: The percentage of pixels that must match.
  ///   - size: The size of the scene.
  public static func image(precision: Float = 1, size: CGSize) -> Snapshotting {
    return Snapshotting<UIView, UIImage>.image(
      precision: precision
    ).asyncPullback(
      Formatting<SCNScene, UIView>.image(
        size: size
      ).format
    )
  }
}

extension Formatting where Value == SCNScene, Format == UIView {
  /// A format strategy for converting layers to images.
  public static func image(size: CGSize) -> Formatting {
    Self(format: { scene in
        let view = SCNView(frame: .init(x: 0, y: 0, width: size.width, height: size.height))
        view.scene = scene
        return view
    })
  }
}
#endif

#endif
