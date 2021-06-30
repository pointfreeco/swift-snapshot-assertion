import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension Snapshotting where Value == URLRequest, Format == String {
  /// A snapshot strategy for comparing requests based on raw equality.
  public static let raw = Snapshotting.raw(pretty: false)

  /// A snapshot strategy for comparing requests based on raw equality.
  ///
  /// - Parameter pretty: Attempts to pretty print the body of the request (supports JSON).
  public static func raw(pretty: Bool) -> Snapshotting {
    return SimplySnapshotting.lines.pullback { (request: URLRequest) in
      let method = "\(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "(null)")"

      let headers = (request.allHTTPHeaderFields ?? [:])
        .map { key, value in "\(key): \(value)" }
        .sorted()

      let body: [String]
      do {
        if pretty, #available(iOS 11.0, macOS 10.13, tvOS 11.0, *) {
          body = try request.data
            .map { try JSONSerialization.jsonObject(with: $0, options: []) }
            .map { try JSONSerialization.data(withJSONObject: $0, options: [.prettyPrinted, .sortedKeys]) }
            .map { ["\n\(String(decoding: $0, as: UTF8.self))"] }
            ?? []
        } else {
          throw NSError(domain: "co.pointfree.Never", code: 1, userInfo: nil)
        }
      }
      catch {
        body = request.data
          .map { ["\n\(String(decoding: $0, as: UTF8.self))"] }
          ?? []
      }

      return ([method] + headers + body).joined(separator: "\n")
    }
  }
  
  /// A snapshot strategy for comparing requests based on a cURL representation.
  public static let curl = SimplySnapshotting.lines.pullback { (request: URLRequest) in

    var components = ["curl"]

    // HTTP Method
    let httpMethod = request.httpMethod!
    switch httpMethod {
    case "GET": break
    case "HEAD": components.append("--head")
    default: components.append("--request \(httpMethod)")
    }

    // Headers
    if let headers = request.allHTTPHeaderFields {
      for field in headers.keys.sorted() where field != "Cookie" {
        let escapedValue = headers[field]!.replacingOccurrences(of: "\"", with: "\\\"")
        components.append("--header \"\(field): \(escapedValue)\"")
      }
    }

    // Body
    if let httpBodyData = request.data, let httpBody = String(data: httpBodyData, encoding: .utf8) {
      var escapedBody = httpBody.replacingOccurrences(of: "\\\"", with: "\\\\\"")
      escapedBody = escapedBody.replacingOccurrences(of: "\"", with: "\\\"")
      
      components.append("--data \"\(escapedBody)\"")
    }
    
    // Cookies
    if let cookie = request.allHTTPHeaderFields?["Cookie"] {
      let escapedValue = cookie.replacingOccurrences(of: "\"", with: "\\\"")
      components.append("--cookie \"\(escapedValue)\"")
    }

    // URL
    components.append("\"\(request.url!.absoluteString)\"")

    return components.joined(separator: " \\\n\t")
  }
}

// MARK: - URLRequest extensions

private extension URLRequest {

  /// Yields the data, if any, contained in the receiver, coming either from `httpBody` or `httpBodyStream`.
  var data: Data? { httpBody ?? (httpBodyStream.map { Data(reading: $0) } ?? nil) }

}

// MARK: - Data extensions

private extension Data {

  /**
   Consumes the specified input stream, creating a new `Data` object with its content.

   - Parameter input: The input stream to read data from.
   - Note: Closes the specified stream before ending.
   */
  init(reading input: InputStream, withBufferSize bufferSize: UInt = 1024) {
    self.init()

    input.open()
    defer { input.close() }

    let bufferSize = Int(bufferSize)
    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
    defer { buffer.deallocate() }

    while input.hasBytesAvailable {
      let read = input.read(buffer, maxLength: bufferSize)
      guard read > 0 else { return }
      self.append(buffer, count: read)
    }
  }

}
