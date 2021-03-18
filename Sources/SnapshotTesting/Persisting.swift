import Foundation
import XCTest

/// A type representing the ability to read/write a snapshottable value from/to data for snapshot testing.
public struct Persisting<Value> {
  /// Converts a value _to_ data.
  public var toData: (Value) -> Data

  /// Produces a value _from_ data.
  public var fromData: (Data) -> Value

  /// Creates a new `Persisting` on `Value`.
  ///
  /// - Parameters:
  ///   - toData: A function used to convert a value _to_ data.
  ///   - value: A value to convert into data.
  ///   - fromData: A function used to produce a value _from_ data.
  ///   - data: Data to convert into a value.
  public init(
    toData: @escaping (_ value: Value) -> Data,
    fromData: @escaping (_ data: Data) -> Value
  ) {
    self.toData = toData
    self.fromData = fromData
  }

  /// Transforms a strategy on `Value`s into a strategy on `NewValue`s through a function `(NewValue) -> Value`.
  ///
  /// - Parameters:
  ///   - toValue: A transform function from `NewValue` into `Value`.
  ///   - fromValue: A transform function from `Value` into `NewValue`.
  public func pullback<NewValue>(
    toValue: @escaping (_ value: NewValue) -> Value,
    fromValue: @escaping (_ data: Value) -> NewValue
  ) -> Persisting<NewValue> {
    return Persisting<NewValue>(
      toData: { newValue in
        self.toData(toValue(newValue))
      },
      fromData: { data in
        fromValue(self.fromData(data))
      }
    )
  }
}
