extension Snapshotting where Format == String {
  /// A snapshot strategy that captures a value's textual description from `String`'s `init(description:)`
  /// initializer.
  public static var description: Snapshotting {
    return SimplySnapshotting.lines.asyncPullback(
      Formatting.description.format
    )
  }
}

extension Formatting where Format == String {
  /// A format strategy for converting layers to images.
  public static var description: Formatting {
    Self(format: { value in
        String(describing: value)
    })
  }
}
