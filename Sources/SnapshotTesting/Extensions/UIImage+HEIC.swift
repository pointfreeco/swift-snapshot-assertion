#if os(iOS) || os(tvOS)
import AVFoundation
import UIKit

@available(tvOSApplicationExtension 11.0, *)
extension UIImage {
  func heicData(compressionQuality: Float = 1.0) -> Data? {
    let data = NSMutableData()
    
    guard let imageDestination = CGImageDestinationCreateWithData(data, AVFileType.heic as CFString, 1, nil) else {
      return nil
    }
    
    guard let cgImage = cgImage else {
      return nil
    }
    
    let options: NSDictionary = [
      kCGImageDestinationLossyCompressionQuality: compressionQuality
    ]
    
    CGImageDestinationAddImage(imageDestination, cgImage, options)
    
    guard CGImageDestinationFinalize(imageDestination) else {
      return nil
    }
    
    return data as Data
  }
}
#endif
