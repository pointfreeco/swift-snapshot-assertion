#if os(Linux)
import XCTest

/// An XCTest subclass that provides snaphot testing helpers.
open class SnapshotTestCase: XCTestCase {
  /// Whether or not to record all new references.
  open var record = false

  /// Enhances failure messages with a command line expression that can be copied and pasted into a terminal.
  ///
  ///     diffTool = "ksdiff"
  open var diffTool: String? = nil

  /// Asserts that a given value matches a reference on disk.
  ///
  /// - Parameters:
  ///   - value: A value to compare against a reference.
  ///   - snapshotting: A strategy for serializing, deserializing, and comparing values.
  ///   - name: An optional description of the snapshot.
  ///   - recording: Whether or not to record a new reference.
  ///   - timeout: The amount of time a snapshot must be generated in.
  ///   - file: The file in which failure occurred. Defaults to the file name of the test case in which this function was called.
  ///   - testName: The name of the test in which failure occurred. Defaults to the function name of the test case in which this function was called.
  ///   - line: The line number on which failure occurred. Defaults to the line number on which this function was called.
  public func assertSnapshot<Value, Format>(
    matching value: Value,
    as snapshotting: Snapshotting<Value, Format>,
    named name: String? = nil,
    record recording: Bool = false,
    timeout: TimeInterval = 5,
    file: StaticString = #file,
    testName: String = #function,
    line: UInt = #line
    ) {

    let recording = recording || self.record

    do {
      let fileUrl = URL(fileURLWithPath: "\(file)")
      let fileName = fileUrl.deletingPathExtension().lastPathComponent
      let directoryUrl = fileUrl.deletingLastPathComponent()
      let snapshotDirectoryUrl: URL = directoryUrl
        .appendingPathComponent("__Snapshots__")
        .appendingPathComponent(fileName)

      let identifier: String
      if let name = name {
        identifier = sanitizePathComponent(name)
      } else {
        identifier = String(counter)
        counter += 1
      }

      let testName = sanitizePathComponent(testName)
      let snapshotFileUrl = snapshotDirectoryUrl
        .appendingPathComponent("\(testName).\(identifier)")
        .appendingPathExtension(snapshotting.pathExtension ?? "")
      let fileManager = FileManager.default
      try fileManager.createDirectory(at: snapshotDirectoryUrl, withIntermediateDirectories: true)

      let tookSnapshot = self.expectation(description: "Took snapshot")
      var optionalDiffable: Format?
      snapshotting.snapshot(value).run { b in
        optionalDiffable = b
        tookSnapshot.fulfill()
      }
      #if os(Linux)
      self.waitForExpectations(timeout: timeout)
      #else
      self.wait(for: [tookSnapshot], timeout: timeout)
      #endif

      guard let diffing = optionalDiffable else {
        XCTFail("Couldn't snapshot value", file: file, line: line)
        return
      }

      guard !recording, fileManager.fileExists(atPath: snapshotFileUrl.path) else {
        try snapshotting.diffing.toData(diffing).write(to: snapshotFileUrl)
        XCTFail("Recorded snapshot: …\n\n\"\(snapshotFileUrl.path)\"", file: file, line: line)
        return
      }

      let data = try Data(contentsOf: snapshotFileUrl)
      let reference = snapshotting.diffing.fromData(data)

      guard let (failure, attachments) = snapshotting.diffing.diff(reference, diffing) else {
        return
      }

      let artifactsUrl = URL(
        fileURLWithPath: ProcessInfo.processInfo.environment["SNAPSHOT_ARTIFACTS"] ?? NSTemporaryDirectory()
      )
      let artifactsSubUrl = artifactsUrl.appendingPathComponent(fileName)
      try fileManager.createDirectory(at: artifactsSubUrl, withIntermediateDirectories: true)
      let failedSnapshotFileUrl = artifactsSubUrl.appendingPathComponent(snapshotFileUrl.lastPathComponent)
      try snapshotting.diffing.toData(diffing).write(to: failedSnapshotFileUrl)

      if !attachments.isEmpty {
        #if !os(Linux)
        XCTContext.runActivity(named: "Attached Failure Diff") { activity in
          attachments.forEach {
            activity.add($0.rawValue)
          }
        }
        #endif
      }

      let diffMessage = self.diffTool
        .map { "\($0) \"\(snapshotFileUrl.path)\" \"\(failedSnapshotFileUrl.path)\"" }
        ?? "@\(minus)\n\"\(snapshotFileUrl.path)\"\n@\(plus)\n\"\(failedSnapshotFileUrl.path)\""
      let message = """
      \(failure.trimmingCharacters(in: .whitespacesAndNewlines))

      \(diffMessage)
      """
      XCTFail(message, file: file, line: line)
    } catch {
      XCTFail(error.localizedDescription, file: file, line: line)
    }
  }
  
  /// Asserts that a given value matches a reference on disk.
  ///
  /// - Parameters:
  ///   - value: A value to compare against a reference.
  ///   - snapshotting: A strategy for serializing, deserializing, and comparing values.
  ///   - bundle: Bundle containing the resource.
  ///   - name: An optional description of the snapshot.
  ///   - recording: Whether or not to record a new reference.
  ///   - timeout: The amount of time a snapshot must be generated in.
  ///   - file: The file in which failure occurred. Defaults to the file name of the test case in which this function was called.
  ///   - testName: The name of the test in which failure occurred. Defaults to the function name of the test case in which this function was called.
  ///   - line: The line number on which failure occurred. Defaults to the line number on which this function was called.
  public func assertSnapshotFromResources<Value, Format>(
    matching value: @autoclosure () throws -> Value,
    as snapshotting: Snapshotting<Value, Format>,
    bundle: Bundle,
    named name: String? = nil,
    record recording: Bool,
    timeout: TimeInterval = 5,
    file: StaticString = #file,
    testName: String = #function,
    line: UInt = #line
    ) {

      do {
        let fileUrl = URL(fileURLWithPath: "\(file)")
        let fileName = fileUrl.deletingPathExtension().lastPathComponent

        let identifier: String
        if let name = name {
          identifier = sanitizePathComponent(name)
        } else {
          identifier = String(counter)
          counter += 1
        }

        let testName = sanitizePathComponent(testName)

        let tookSnapshot = self.expectation(description: "Took snapshot")
        var optionalDiffable: Format?
        snapshotting.snapshot(try value()).run { b in
          optionalDiffable = b
          tookSnapshot.fulfill()
        }
        #if os(Linux)
        self.waitForExpectations(timeout: timeout)
        #else
        self.wait(for: [tookSnapshot], timeout: timeout)
        #endif

        guard let diffable = optionalDiffable else {
          XCTFail("Couldn't snapshot value", file: file, line: line)
          return
        }

        let resourceName = "\(fileName).\(testName).\(identifier)"
        let fullResourceName = "\(resourceName).\(snapshotting.pathExtension ?? "")"
        let directoryUrl = fileUrl.deletingLastPathComponent()
        let writableSnapshotDirectoryUrl: URL = directoryUrl
          .appendingPathComponent("__Snapshots__")
        
        let writableSnapshotFileUrl = writableSnapshotDirectoryUrl
          .appendingPathComponent(resourceName)
          .appendingPathExtension(snapshotting.pathExtension ?? "")
        
        let fileManager = FileManager.default
        
        guard !recording else {
          let snapshotFileDidExist = fileManager.fileExists(atPath: writableSnapshotFileUrl.path)
          
          try fileManager.createDirectory(at: writableSnapshotDirectoryUrl, withIntermediateDirectories: true)
          try snapshotting.diffing.toData(diffable).write(to: writableSnapshotFileUrl)
          
          let message = snapshotFileDidExist
            ? "Updated resource \(fullResourceName)"
            : "New resource created \(fullResourceName)"
          XCTFail(message, file: file, line: line)
          return
        }
        
        guard let resourcePathUrl = bundle.url(forResource: resourceName, withExtension: snapshotting.pathExtension) else {
          XCTFail("Could not find resource \(fullResourceName)", file: file, line: line)
          return
        }

        let data = try Data(contentsOf: resourcePathUrl)
        let reference = snapshotting.diffing.fromData(data)

        guard let (failure, attachments) = snapshotting.diffing.diff(reference, diffable) else {
          return
        }

        let artifactsUrl = URL(
          fileURLWithPath: ProcessInfo.processInfo.environment["SNAPSHOT_ARTIFACTS"] ?? NSTemporaryDirectory()
        )
        let artifactsSubUrl = artifactsUrl.appendingPathComponent(fileName)
        try fileManager.createDirectory(at: artifactsSubUrl, withIntermediateDirectories: true)
        let failedSnapshotFileUrl = artifactsSubUrl.appendingPathComponent(resourcePathUrl.lastPathComponent)
        try snapshotting.diffing.toData(diffable).write(to: failedSnapshotFileUrl)

        if !attachments.isEmpty {
          #if !os(Linux)
          XCTContext.runActivity(named: "Attached Failure Diff") { activity in
            attachments.forEach {
              activity.add($0.rawValue)
            }
          }
          #endif
        }

        let diffMessage = self.diffTool
          .map { "\($0) \"\(failedSnapshotFileUrl.path)\"" }
          ?? "@\(minus)\n\(writableSnapshotFileUrl.path)\n@\(plus)\n\"\(failedSnapshotFileUrl.path)\""
        let message = """
        \(failure.trimmingCharacters(in: .whitespacesAndNewlines))

        \(diffMessage)
        """
        XCTFail(message, file: file, line: line)
      } catch {
        XCTFail(error.localizedDescription, file: file, line: line)
      }
  }

  private var counter = 1
}
#endif
