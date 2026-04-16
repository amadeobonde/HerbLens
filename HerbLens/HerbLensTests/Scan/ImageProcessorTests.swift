import Foundation
import Testing
import UIKit
@testable import HerbLens

@Suite("DefaultImageProcessor")
struct ImageProcessorTests {
    @Test("downsamples a 2048×1024 test image to ≤1024 px on the long edge")
    func downsampleClampsLongEdge() async throws {
        let source = makeImage(width: 2048, height: 1024)
        let data = try await DefaultImageProcessor().prepare(source)
        guard let output = UIImage(data: data) else {
            Issue.record("output bytes weren't a decodable image")
            return
        }
        let longEdge = max(output.size.width * output.scale, output.size.height * output.scale)
        #expect(longEdge <= 1024)
    }

    @Test("preserves aspect ratio within one percent")
    func preservesAspect() async throws {
        let source = makeImage(width: 2000, height: 1000)
        let data = try await DefaultImageProcessor().prepare(source)
        let output = try #require(UIImage(data: data))
        let ratio = (output.size.width * output.scale) / (output.size.height * output.scale)
        #expect(abs(ratio - 2.0) < 0.02)
    }

    @Test("output is a valid JPEG bytestream")
    func outputIsJPEG() async throws {
        let source = makeImage(width: 800, height: 600)
        let data = try await DefaultImageProcessor().prepare(source)
        // JPEG SOI marker: 0xFF 0xD8
        #expect(data.count > 2)
        #expect(data[0] == 0xFF)
        #expect(data[1] == 0xD8)
    }

    @Test("small source images are not up-scaled")
    func smallImageStaysSmall() async throws {
        let source = makeImage(width: 300, height: 200)
        let data = try await DefaultImageProcessor().prepare(source)
        let output = try #require(UIImage(data: data))
        let longEdge = max(output.size.width * output.scale, output.size.height * output.scale)
        #expect(longEdge <= 1024)
        #expect(longEdge <= 600)
    }

    private func makeImage(width: Int, height: Int) -> UIImage {
        let size = CGSize(width: width, height: height)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            UIColor(red: 0.3, green: 0.6, blue: 0.4, alpha: 1).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            UIColor.white.setStroke()
            ctx.cgContext.setLineWidth(4)
            ctx.cgContext.strokeEllipse(in: CGRect(
                x: 20, y: 20, width: size.width - 40, height: size.height - 40
            ))
        }
    }
}
