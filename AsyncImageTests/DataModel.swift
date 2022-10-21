import SwiftUI

struct SearchResult: Codable, Hashable {
    var total: Int
    var totalPages: Int
    var results: [Photo]
}

struct Photo: Identifiable, Codable, Hashable {
    var id: String
    var width: Int
    var height: Int
    var description: String?
    var urls: URLS

    struct URLS: Codable, Hashable {
        var raw, full, regular, small, thumb: URL
    }

    var size: CGSize {
        CGSize(width: width, height: height)
    }
}

extension Photo {
    static let sample: [Photo] = {
        do {
            let data = try Data(contentsOf: Bundle.main.url(forResource: "beach", withExtension: "json")!)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(SearchResult.self, from: data).results
        } catch {
            print(error)
            return []
        }
    }()
}
