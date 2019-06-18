import XCTest
@testable import SnapshotTesting
extension InlineSnapshotsValidityTests {
  func testCreateSnapshotMultiLine() {
    let diffable = #######"""
    NEW_SNAPSHOT
    """#######

    _assertInlineSnapshot(matching: diffable, as: .lines, with: """
    NEW_SNAPSHOT
    """)
  }
}