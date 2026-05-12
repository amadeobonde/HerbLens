import Foundation

public struct PackagedProduct: Codable, Sendable, Identifiable, Hashable {
    public let id: String
    public let barcode: String
    public let name: String
    public let brand: String?
    public let imageUrl: String?
    public let ingredients: String?
}

public protocol BarcodeService: Sendable {
    func lookup(barcode: String) async throws -> PackagedProduct?
}

// MARK: - Open Food Facts Implementation

public struct OpenFoodFactsService: BarcodeService {
    public init() {}
    
    public func lookup(barcode: String) async throws -> PackagedProduct? {
        // Open Food Facts API v2 endpoint for product by barcode
        guard let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(barcode)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("HerbLens/1.0 (amadeobonde@example.com)", forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return nil // Product not found or server error
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        // Basic parsing for Open Food Facts response structure
        struct OFFResponse: Codable {
            let status: Int
            let product: OFFProduct?
            
            struct OFFProduct: Codable {
                let id: String
                let productName: String?
                let brands: String?
                let imageUrl: String?
                let ingredientsText: String?
            }
        }
        
        let offResponse = try decoder.decode(OFFResponse.self, from: data)
        guard offResponse.status == 1, let product = offResponse.product else {
            return nil
        }
        
        return PackagedProduct(
            id: product.id,
            barcode: barcode,
            name: product.productName ?? "Unknown Product",
            brand: product.brands,
            imageUrl: product.imageUrl,
            ingredients: product.ingredientsText
        )
    }
}
