import Foundation
import XCTest

extension Snapshotting where Value == Data, Format == Data {
  public static var data: Snapshotting {
    return .init(
      pathExtension: nil,
      diffing: .init(persist: Persisting.data) { old, new in
        guard old != new else { return nil }
        let message = old.count == new.count
          ? "Expected data to match"
          : "Expected \(new) to match \(old)"
        return (message, [])
      }
    )
  }
}

extension Persisting where Value == Data {
  public static var data: Persisting {
    return Persisting(
      toData: { $0 },
      fromData: { $0 }
    )
  }
}
