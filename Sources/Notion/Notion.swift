import Foundation

/// The Notion actor is responsible for managing the Notion API.
public actor Notion {
    /// The integration token used to authenticate with the Notion API.
    private let token: String
    private let baseURL = URL(string: "https://api.notion.com/v1/")!
    private let apiVersion = "2022-06-28"

    init(token: String) {
        self.token = token
    }

    /// Internal routine to create a URL request with the proper headers.
    private func getRequest(for path: String, queryItems: [String: String]? = nil) async throws -> URLRequest {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: true)!
        
        if let queryItems = queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let url = components.url else {
            throw NSError(domain: "NotionError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL components"])
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiVersion, forHTTPHeaderField: "Notion-Version")
        return request
    }
    
    /// Processes API response data and checks for error responses
    private func processAPIResponse<T: Decodable>(data: Data) throws -> T {
        // Debug: Pretty-print the JSON response
        if let jsonObject = try? JSONSerialization.jsonObject(with: data),
           let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
           let prettyString = String(data: prettyData, encoding: .utf8) {
            print("API Response:\n\(prettyString)")
        }

        let decoder = JSONDecoder()
        
        // Check if the response is an error
        if let errorResponse = try? decoder.decode(NotionAPIError.Response.self, from: data),
           errorResponse.object == "error" {
            throw NotionAPIError(response: errorResponse)
        }
        
        // If not an error, decode as the expected type
        return try decoder.decode(T.self, from: data)
    }

    public func getUsers() async throws -> [User] {
        let request = try await getRequest(for: "users")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, 
           !(200...299).contains(httpResponse.statusCode) {
            // For debugging purposes only
            if let json = String(data: data, encoding: .utf8) {
                print("Error response: \(json)")
            }
        }
        
        let listResponse: ListResponse<User> = try processAPIResponse(data: data)
        return listResponse.results
    }

    public func getPage(id: String) async throws -> Page {
        let request = try await getRequest(for: "pages/\(id)")
        let (data, _) = try await URLSession.shared.data(for: request)
        return try processAPIResponse(data: data)
    }

    public func getBlockChildren(id: String, startCursor: String? = nil, pageSize: Int? = nil) async throws -> BlockChildrenResponse {
        var queryItems: [String: String] = [:]
        if let startCursor = startCursor {
            queryItems["start_cursor"] = startCursor
        }
        if let pageSize = pageSize {
            queryItems["page_size"] = "\(pageSize)"
        }
        
        let request = try await getRequest(for: "blocks/\(id)/children", queryItems: queryItems.isEmpty ? nil : queryItems)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, 
           !(200...299).contains(httpResponse.statusCode) {
            // For debugging purposes only
            if let json = String(data: data, encoding: .utf8) {
                print("Error response: \(json)")
            }
        }
        
        let listResponse: ListResponse<Block> = try processAPIResponse(data: data)
        return BlockChildrenResponse(object: listResponse.object, results: listResponse.results, nextCursor: listResponse.nextCursor, hasMore: listResponse.hasMore)
    }
    
    /// Returns an AsyncSequence that lazily iterates through all children blocks
    nonisolated public func blockChildren(id: String, pageSize: Int? = nil) -> BlockChildrenSequence {
        BlockChildrenSequence(notion: self, blockID: id, pageSize: pageSize)
    }
}

/// Base protocol for all Notion objects
public protocol NotionObject: Sendable, Codable {
    var object: String { get }
}
