import XCTest
@testable import SnapshotTesting
extension InlineSnapshotsValidityTests {
  func testCreateSnapshotEscapedNewlineLastLine() {
    let diffable = #######"""
    abc \
    cde \
    """#######

    _assertInlineSnapshot(matching: diffable, as: .lines, with: #"""
    abc \
    cde \
    """#)
  }
}