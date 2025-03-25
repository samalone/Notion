// The Swift Programming Language
// https://docs.swift.org/swift-book

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
    private func getRequest(for path: String) async throws -> URLRequest {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiVersion, forHTTPHeaderField: "Notion-Version")
        return request
    }
    
    /// Processes API response data and checks for error responses
    private func processAPIResponse<T: Decodable>(data: Data) throws -> T {
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

    public func getBlockChildren(id: String) async throws -> [Block] {
        let request = try await getRequest(for: "blocks/\(id)/children")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, 
           !(200...299).contains(httpResponse.statusCode) {
            // For debugging purposes only
            if let json = String(data: data, encoding: .utf8) {
                print("Error response: \(json)")
            }
        }
        
        let listResponse: ListResponse<Block> = try processAPIResponse(data: data)
        return listResponse.results
    }
}

// MARK: - Error Types

/// Custom error for Notion API errors
public struct NotionAPIError: Error, CustomStringConvertible {
    public struct Response: Codable, Sendable {
        public let object: String
        public let status: Int
        public let code: String
        public let message: String
        public let requestID: String?
        
        private enum CodingKeys: String, CodingKey {
            case object, status, code, message
            case requestID = "request_id"
        }
    }
    
    public let response: Response
    
    public var description: String {
        "Notion API Error: [\(response.code)] \(response.message) (Status: \(response.status))"
    }
    
    public var localizedDescription: String {
        description
    }
}

// MARK: - Notion API Models

/// Base protocol for all Notion objects
public protocol NotionObject: Sendable, Codable {
    var object: String { get }
}

/// Response wrapper for paginated lists of objects
public struct ListResponse<T: Codable & Sendable>: Sendable, Codable {
    public let object: String
    public let results: [T]
    public let nextCursor: String?
    public let hasMore: Bool
    
    private enum CodingKeys: String, CodingKey {
        case object, results
        case nextCursor = "next_cursor"
        case hasMore = "has_more"
    }
}
