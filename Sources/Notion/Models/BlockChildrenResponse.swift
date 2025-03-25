import Foundation

/// Response for listing children of a block
public struct BlockChildrenResponse: Sendable, Codable {
    /// Type of object. Always "list".
    public let object: String
    
    /// List of Block objects
    public let results: [Block]
    
    /// Pagination information
    public let nextCursor: String?
    public let hasMore: Bool
    
    private enum CodingKeys: String, CodingKey {
        case object, results
        case nextCursor = "next_cursor"
        case hasMore = "has_more"
    }
}
