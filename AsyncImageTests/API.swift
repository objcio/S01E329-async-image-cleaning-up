import Foundation

func load(query: String, apiKey: String) async throws -> [Photo] {
    var request = URLRequest(url: URL(string: "https://api.unsplash.com/search/photos?query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)&per_page=25")!)
    try await Task.sleep(nanoseconds: NSEC_PER_SEC)
    request.setValue("Client-ID \(apiKey)", forHTTPHeaderField: "Authorization")
    let (data, _) = try await URLSession.shared.data(for: request)
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return try decoder.decode(SearchResult.self, from: data).results
}
