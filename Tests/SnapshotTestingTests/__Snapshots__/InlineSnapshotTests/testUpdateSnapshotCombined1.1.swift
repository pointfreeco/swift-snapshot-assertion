import XCTest
@testable import SnapshotTesting
extension InlineSnapshotsValidityTests {
  func testUpdateSnapshotCombined1() {
    let diffable = #######"""
    ▿ User
      - bio: "Blobbed around the world."
      - id: 1
      - name: "Bl#\"\"#obby"
    """#######

    _assertInlineSnapshot(matching: diffable, as: .lines, with: ##"""
    ▿ User
      - bio: "Blobbed around the world."
      - id: 1
      - name: "Bl#\"\"#obby"
    """##)
  }
}