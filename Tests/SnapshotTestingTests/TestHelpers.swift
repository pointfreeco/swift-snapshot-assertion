import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import SnapshotTesting
import XCTest

#if os(iOS)
let platform = "ios"
#elseif os(tvOS)
let platform = "tvos"
#elseif os(macOS)
let platform = "macos"
extension NSTextField {
  var text: String {
    get { return self.stringValue }
    set { self.stringValue = newValue }
  }
}
#endif

#if os(macOS) || os(iOS) || os(tvOS)
extension CGPath {
  /// Creates an approximation of a heart at a 45º angle with a circle above, using all available element types:
  static var heart: CGPath {
    let scale: CGFloat = 30.0
    let path = CGMutablePath()

    path.move(to: CGPoint(x: 0.0 * scale, y: 0.0 * scale))
    path.addLine(to: CGPoint(x: 0.0 * scale, y: 2.0 * scale))
    path.addQuadCurve(
        to: CGPoint(x: 1.0 * scale, y: 3.0 * scale),
        control: CGPoint(x: 0.125 * scale, y: 2.875 * scale)
    )
    path.addQuadCurve(
        to: CGPoint(x: 2.0 * scale, y: 2.0 * scale),
        control: CGPoint(x: 1.875 * scale, y: 2.875 * scale)
    )
    path.addCurve(
        to: CGPoint(x: 3.0 * scale, y: 1.0 * scale),
        control1: CGPoint(x: 2.5 * scale, y: 2.0 * scale),
        control2: CGPoint(x: 3.0 * scale, y: 1.5 * scale)
    )
    path.addCurve(
        to: CGPoint(x: 2.0 * scale, y: 0.0 * scale),
        control1: CGPoint(x: 3.0 * scale, y: 0.5 * scale),
        control2: CGPoint(x: 2.5 * scale, y: 0.0 * scale)
    )
    path.addLine(to: CGPoint(x: 0.0 * scale, y: 0.0 * scale))
    path.closeSubpath()

    path.addEllipse(in: CGRect(
      origin: CGPoint(x: 2.0 * scale, y: 2.0 * scale),
      size: CGSize(width: scale, height: scale)
    ))

    return path
  }
}
#endif

#if os(iOS) || os(tvOS)
extension UIBezierPath {
  /// Creates an approximation of a heart at a 45º angle with a circle above, using all available element types:
  static var heart: UIBezierPath {
    UIBezierPath(cgPath: .heart)
  }
}
#endif

#if os(macOS)
extension NSBezierPath {
  /// Creates an approximation of a heart at a 45º angle with a circle above, using all available element types:
  static var heart: NSBezierPath {
    let scale: CGFloat = 30.0
    let path = NSBezierPath()

    path.move(to: CGPoint(x: 0.0 * scale, y: 0.0 * scale))
    path.line(to: CGPoint(x: 0.0 * scale, y: 2.0 * scale))
    path.curve(
        to: CGPoint(x: 1.0 * scale, y: 3.0 * scale),
        controlPoint1: CGPoint(x: 0.0 * scale, y: 2.5 * scale),
        controlPoint2: CGPoint(x: 0.5 * scale, y: 3.0 * scale)
    )
    path.curve(
        to: CGPoint(x: 2.0 * scale, y: 2.0 * scale),
        controlPoint1: CGPoint(x: 1.5 * scale, y: 3.0 * scale),
        controlPoint2: CGPoint(x: 2.0 * scale, y: 2.5 * scale)
    )
    path.curve(
        to: CGPoint(x: 3.0 * scale, y: 1.0 * scale),
        controlPoint1: CGPoint(x: 2.5 * scale, y: 2.0 * scale),
        controlPoint2: CGPoint(x: 3.0 * scale, y: 1.5 * scale)
    )
    path.curve(
        to: CGPoint(x: 2.0 * scale, y: 0.0 * scale),
        controlPoint1: CGPoint(x: 3.0 * scale, y: 0.5 * scale),
        controlPoint2: CGPoint(x: 2.5 * scale, y: 0.0 * scale)
    )
    path.line(to: CGPoint(x: 0.0 * scale, y: 0.0 * scale))
    path.close()

    path.appendOval(in: CGRect(
      origin: CGPoint(x: 2.0 * scale, y: 2.0 * scale),
      size: CGSize(width: scale, height: scale)
    ))

    return path
  }
}
#endif

/// `URLProtocol` subclass that allows observing requests.
class URLProtocolStub: URLProtocol {

  private static var requestObserver: ((URLRequest) -> Void)?
  private static let anyResponse = URLResponse(url: URL(string: "www.testing.com")!,
                                               mimeType: "",
                                               expectedContentLength: 0,
                                               textEncodingName: "")

  /**
   Sets the request observer closure to use when processing requests.

   Once set, and after calling `startInterceptingRequests`, the given closure will be called
   every time there is a request to process, so re-use this function whenever a new closure is needed.
   The given closure will be removed once `stopInterceptingRequests` gets called.

   - Parameter observer: The closure to call whenever there is a request to process.
   */
  static func observeRequests(observer: @escaping (URLRequest) -> Void) { requestObserver = observer }

  /// Registers `Self` with the `URL loading system` to begin receiving requests.
  static func startInterceptingRequests() { _ = URLProtocol.registerClass(URLProtocolStub.self) }

  /// Unregisters `Self` from the `URL loading system` to stop receiving requests.
  /// Additionally, it removes the configured request observer closure, if any.
  static func stopInterceptingRequests() {
    URLProtocol.unregisterClass(URLProtocolStub.self)
    requestObserver = nil
  }

  override class func canInit(with request: URLRequest) -> Bool { true }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

  override func startLoading() {
    Self.requestObserver.map { $0(request) }
    client?.urlProtocol(self, didLoad: .init())
    client?.urlProtocol(self, didReceive: Self.anyResponse, cacheStoragePolicy: .notAllowed)
    client?.urlProtocolDidFinishLoading(self)
  }

  override func stopLoading() {}

}
