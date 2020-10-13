#if os(macOS) || os(iOS) || os(tvOS)
import CoreGraphics
import XCTest

#if os(iOS) || os(tvOS)
import MobileCoreServices
#endif

extension Diffing where Value == CGImage {
  /// A pixel-diffing strategy for CGImage's which requires a 100% match.
  public static var image: Diffing {
    return .image(precision: 1)
  }
  
  /// A pixel-diffing strategy for CGImage that allows customizing how precise the matching must be.
  ///
  /// - Parameter precision: A value between 0 and 1, where 1 means the images must match 100% of their pixels.
  /// - Returns: A new diffing strategy.
  public static func image(precision: Float = 1) -> Diffing {
    return Diffing(
      toData: { Self.toData($0)! },
      fromData: { Self.fromData($0)! },
      diff: { Self.diff($0, $1, precision: precision) }
    )
  }

  public static func toData(_ image: Value) -> Data? {
    guard let mutableData = CFDataCreateMutable(nil, 0) else { return nil}
    guard let dest = CGImageDestinationCreateWithData(mutableData, kUTTypePNG, 1, nil) else { return nil}
    CGImageDestinationAddImage(dest, image, nil)
    guard CGImageDestinationFinalize(dest) else {
      return nil
    }
    return mutableData as Data
  }

  public static func fromData(_ data: Data) -> Value? {
    guard let provider = CGDataProvider(data: data as CFData) else { return nil}
    return CGImage(
      pngDataProviderSource: provider,
      decode: nil,
      shouldInterpolate: false,
      intent: .defaultIntent
    )
  }
  
  public static func diff(_ old: Value, _ new: Value, precision: Float) -> (String, [XCTAttachment])? {
    guard !compare(old, new, precision: precision) else { return nil }
    let difference = SnapshotTesting.diff(old, new)
    let oldSize = CGSize(width: old.width, height: old.height)
    let newSize = CGSize(width: new.width, height: new.height)
    let message = newSize == oldSize
      ? "Newly-taken snapshot does not match reference."
      : "Newly-taken snapshot@\(newSize) does not match reference@\(oldSize)."
    let attachments = self.attachmentsFor(old: old, new: new, difference: difference)
    return (message, attachments)
  }
  
  #if os(macOS)
  private static func attachmentsFor(old: CGImage, new: CGImage, difference: CGImage) -> [XCTAttachment] {
    func attachmentFrom(image: CGImage, named name: String) -> XCTAttachment {
      let size = CGSize(width: image.width, height: image.height)
      let attachment = XCTAttachment(image: NSImage(cgImage: image, size: size))
      attachment.name = "reference"
      return attachment
    }
    let oldAttachment = attachmentFrom(image: old, named: "reference")
    let newAttachment = attachmentFrom(image: new, named: "failure")
    let differenceAttachment = attachmentFrom(image: difference, named: "difference")
    return [oldAttachment, newAttachment, differenceAttachment]
  }
  #elseif os(iOS) || os(tvOS)
  private static func attachmentsFor(old: CGImage, new: CGImage, difference: CGImage) -> [XCTAttachment] {
    func attachmentFrom(image: CGImage, named name: String) -> XCTAttachment {
      let attachment = XCTAttachment(image: UIImage(cgImage: image))
      attachment.name = "reference"
      return attachment
    }
    let oldAttachment = attachmentFrom(image: old, named: "reference")
    let newAttachment = attachmentFrom(image: new, named: "failure")
    let differenceAttachment = attachmentFrom(image: difference, named: "difference")
    return [oldAttachment, newAttachment, differenceAttachment]
  }
  #else
  private static func attachmentsFor(old: CGImage, new: CGImage, difference: CGImage) -> [XCTAttachment] {
    []
  }
  #endif
}

extension Snapshotting where Value == CGImage, Format == CGImage {
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

private func compare(_ old: CGImage, _ new: CGImage, precision: Float) -> Bool {
  guard old.width != 0 else { return false }
  guard new.width != 0 else { return false }
  guard old.width == new.width else { return false }
  guard old.height != 0 else { return false }
  guard new.height != 0 else { return false }
  guard old.height == new.height else { return false }
  // Values between images may differ due to padding to multiple of 64 bytes per row,
  // because of that a freshly taken view snapshot may differ from one stored as PNG.
  // At this point we're sure that size of both images is the same, so we can go with minimal `bytesPerRow` value
  // and use it to create contexts.
  let minBytesPerRow = min(old.bytesPerRow, new.bytesPerRow)
  let byteCount = minBytesPerRow * old.height

  var oldBytes = [UInt8](repeating: 0, count: byteCount)
  guard let oldContext = context(for: old, bytesPerRow: minBytesPerRow, data: &oldBytes) else { return false }
  guard let oldData = oldContext.data else { return false }
  if let newContext = context(for: new, bytesPerRow: minBytesPerRow), let newData = newContext.data {
    if memcmp(oldData, newData, byteCount) == 0 { return true }
  }
  let toData = Diffing<CGImage>.toData
  let fromData = Diffing<CGImage>.fromData
  let newer: CGImage = fromData(toData(new)!)!
  var newerBytes = [UInt8](repeating: 0, count: byteCount)
  guard let newerContext = context(for: newer, bytesPerRow: minBytesPerRow, data: &newerBytes) else { return false }
  guard let newerData = newerContext.data else { return false }
  if memcmp(oldData, newerData, byteCount) == 0 { return true }
  if precision >= 1 { return false }
  var differentPixelCount = 0
  let threshold = 1 - precision
  for byte in 0..<byteCount {
    if oldBytes[byte] != newerBytes[byte] { differentPixelCount += 1 }
    if Float(differentPixelCount) / Float(byteCount) > threshold { return false}
  }
  return true
}

private func context(for cgImage: CGImage, bytesPerRow: Int, data: UnsafeMutableRawPointer? = nil) -> CGContext? {
  guard
    let space = cgImage.colorSpace,
    let context = CGContext(
      data: data,
      width: cgImage.width,
      height: cgImage.height,
      bitsPerComponent: cgImage.bitsPerComponent,
      bytesPerRow: bytesPerRow,
      space: space,
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )
  else { return nil }

  context.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
  return context
}

internal func diff(_ old: CGImage, _ new: CGImage) -> CGImage {
  let oldCIImage = CIImage(cgImage: old)
  let newCIImage = CIImage(cgImage: new)
  let differenceFilter = CIFilter(
    name: "CIDifferenceBlendMode",
    parameters: [
      kCIInputImageKey: oldCIImage,
      kCIInputBackgroundImageKey: newCIImage,
    ]
  )!
  let context = CIContext()
  let outputSize = CGSize(
    width: max(old.width, new.width),
    height: max(old.height, new.height)
  )
  let outputExtent = CGRect(origin: .zero, size: outputSize)
  let outputImage = differenceFilter.outputImage!
  return context.createCGImage(outputImage, from: outputExtent)!
}
#endif
