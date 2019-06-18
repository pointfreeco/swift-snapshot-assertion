import XCTest
@testable import SnapshotTesting
extension InlineSnapshotsValidityTests {
  func testUpdateSeveralSnapshotsWithMoreLines() {
    let diffable = #######"""
    NEW_SNAPSHOT
    with two lines
    """#######

    let diffable2 = #######"""
    NEW_SNAPSHOT
    """#######

    _assertInlineSnapshot(matching: diffable, as: .lines, with: """
    NEW_SNAPSHOT
    with two lines
    """)
    _assertInlineSnapshot(matching: diffable2, as: .lines, with: """
    NEW_SNAPSHOT
    """)
   }
}