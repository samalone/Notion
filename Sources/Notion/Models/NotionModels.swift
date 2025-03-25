import Foundation

/// Base protocol for common Notion API response properties
public protocol NotionResponse: Sendable, Codable {
    var object: String { get }
}

/// Generic error response from Notion API
public struct NotionErrorResponse: Sendable, Codable {
    public struct Error: Sendable, Codable {
        public let code: String
        public let message: String
    }
    
    public let object: String
    public let status: Int
    public let code: String
    public let message: String
    public let error: Error?
}

/// Helper for handling pagination in Notion API
public struct Pagination: Sendable, Codable {
    public let startCursor: String?
    public let hasMore: Bool
    
    private enum CodingKeys: String, CodingKey {
        case startCursor = "start_cursor"
        case hasMore = "has_more"
    }
}
