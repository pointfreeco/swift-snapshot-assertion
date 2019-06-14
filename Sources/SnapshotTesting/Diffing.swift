import Foundation
import XCTest

/// The ability to compare `Value`s and convert them to and from `Data`.
public struct Diffing<Value> {
  /// Converts a value _to_ data.
  public var toData: (Value) -> Data

  /// Produces a value _from_ data.
  public var fromData: (Data) -> Value

  /// Compares two values. If the values do not match, returns a failure message and artifacts describing the failure.
  public var diff: (Value, Value) -> (String, [XCTAttachment])?

  /// Compares two values. If the values do not match, returns a failure message and artifacts describing the failure in more detail than those returned by `diff`.
  public var artifactDiff: (Value, Value) -> (String, [SnapshotArtifact])?
  
  /// Creates a new `Diffing` on `Value`.
  ///
  /// - Parameters:
  ///   - toData: A function used to convert a value _to_ data.
  ///   - value: A value to convert into data.
  ///   - fromData: A function used to produce a value _from_ data.
  ///   - data: Data to convert into a value.
  ///   - diff: A function used to compare two values. If the values do not match, returns a failure message and artifacts describing the failure.
  ///   - lhs: A value to compare.
  ///   - rhs: Another value to compare.
  public init(
    toData: @escaping (_ value: Value) -> Data,
    fromData: @escaping (_ data: Data) -> Value,
    diff: @escaping (_ lhs: Value, _ rhs: Value) -> (String, [XCTAttachment])?
    ) {
    self.toData = toData
    self.fromData = fromData
    self.diff = diff
    self.artifactDiff = {_, _ in return nil }
  }

  /// Creates a new `Diffing` on `Value`.
  ///
  /// - Parameters:
  ///   - toData: A function used to convert a value _to_ data.
  ///   - value: A value to convert into data.
  ///   - fromData: A function used to produce a value _from_ data.
  ///   - data: Data to convert into a value.
  ///   - diff: A function used to compare two values. If the values do not match, returns a failure message and artifacts describing the failure.
  ///   - lhs: A value to compare.
  ///   - rhs: Another value to compare.
  public init(
      toData: @escaping (_ value: Value) -> Data,
      fromData: @escaping (_ data: Data) -> Value,
      diff: @escaping (_ lhs: Value, _ rhs: Value) -> (String, [SnapshotArtifact])?
      ) {
      self.toData = toData
      self.fromData = fromData
      self.diff = { _, _ in return nil }
      self.artifactDiff = diff
  }
}

/// A represenation of an artifact to be stored as an `XCTAttachment` or to disk.
public struct SnapshotArtifact {
  /// A description of the artifact.
  public enum ArtifactType: String {
    case reference, failure, difference
  }
    
  /// The payload data to be stored.
  public var data: Data
  
  /// The type of artifact to be stored.
  public var artifactType: ArtifactType
  
  /// A uniform type identifier of the payload data.
  public var uniformTypeIdentifier: String?
}
