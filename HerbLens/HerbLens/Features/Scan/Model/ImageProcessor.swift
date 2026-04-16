import Foundation
import ImageIO
import UIKit
import UniformTypeIdentifiers

/// Downsamples and JPEG-encodes an in-memory image so we send as few vision tokens
/// as possible to the `identify-plant` edge function. Anything larger than ~1024 px on
/// the long edge gets tiled aggressively by Gemini — we cap on-device.
public protocol ImageProcessing: Sendable {
    func prepare(_ image: UIImage) async throws -> Data
}

public nonisolated struct DefaultImageProcessor: ImageProcessing {
    public nonisolated static let maxPixelSize: Int = 1024
    public nonisolated static let jpegQuality: CGFloat = 0.8

    public nonisolated init() {}

    public func prepare(_ image: UIImage) async throws -> Data {
        let maxPixel = Self.maxPixelSize
        let quality = Self.jpegQuality
        return try await Task.detached(priority: .userInitiated) {
            try Self.downsampleAndEncode(image, maxPixelSize: maxPixel, quality: quality)
        }.value
    }

    nonisolated static func downsampleAndEncode(
        _ image: UIImage,
        maxPixelSize: Int,
        quality: CGFloat
    ) throws -> Data {
        guard let originalJPEG = image.jpegData(compressionQuality: 1.0) else {
            throw ImageProcessingError.encodingFailed
        }
        guard let source = CGImageSourceCreateWithData(originalJPEG as CFData, nil) else {
            throw ImageProcessingError.decodingFailed
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        ]
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            throw ImageProcessingError.downsampleFailed
        }

        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            output,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            throw ImageProcessingError.encodingFailed
        }
        CGImageDestinationSetProperties(destination, [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary)
        CGImageDestinationAddImage(destination, thumbnail, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw ImageProcessingError.encodingFailed
        }
        return output as Data
    }
}

public enum ImageProcessingError: Error, Equatable, Sendable {
    case decodingFailed
    case downsampleFailed
    case encodingFailed
}
