import XCTest
@testable import SnapshotTesting

class WaitTests: XCTestCase {
  func testWait() {
    var value = "Hello"
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      value = "Goodbye"
    }

    let strategy = Snapshotting.lines.pullback { (_: Void) in
      value
    }

    assertSnapshot(matching: (), as: .wait(for: 1.5, on: strategy))
  }
}
