import Foundation

extension Snapshotting where Value: Encodable, Format == String {
  /// A snapshot strategy for comparing encodable structures based on their JSON representation.
  @available(iOS 11.0, macOS 10.13, tvOS 11.0, *)
  public static var json: Snapshotting {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    return .json(encoder)
  }

  /// A snapshot strategy for comparing encodable structures based on their JSON representation.
  ///
  /// - Parameter encoder: A JSON encoder.
  public static func json(_ encoder: JSONEncoder) -> Snapshotting {
    var snapshotting = SimplySnapshotting.lines.asyncPullback(
      Formatting<Value, Format>.json(encoder: encoder).format
    )
    snapshotting.pathExtension = "json"
    return snapshotting
  }

  /// A snapshot strategy for comparing encodable structures based on their property list representation.
  public static var plist: Snapshotting {
    let encoder = PropertyListEncoder()
    encoder.outputFormat = .xml
    return .plist(encoder)
  }

  /// A snapshot strategy for comparing encodable structures based on their property list representation.
  ///
  /// - Parameter encoder: A property list encoder.
  public static func plist(_ encoder: PropertyListEncoder) -> Snapshotting {
    var snapshotting = SimplySnapshotting.lines.asyncPullback(
      Formatting<Value, Format>.plist(encoder: encoder).format
    )
    snapshotting.pathExtension = "plist"
    return snapshotting
  }
}

extension Formatting where Value: Encodable, Format == String {
  /// A format strategy for converting encodable structures to their JSON representation.
  public static func json(encoder: JSONEncoder) -> Formatting {
    Self(format: { encodable in
      try! String(decoding: encoder.encode(encodable), as: UTF8.self)
    })
  }

  /// A format strategy for converting encodable structures to their property list representation.
  public static func plist(encoder: PropertyListEncoder) -> Formatting {
    Self(format: { encodable in
      try! String(decoding: encoder.encode(encodable), as: UTF8.self)
    })
  }
}
