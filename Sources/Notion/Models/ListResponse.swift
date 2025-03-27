//
//  ListResponse.swift
//  Notion
//
//  Created by Stuart Malone on 3/25/25.
//


/// Response wrapper for paginated lists of objects
public struct ListResponse<T: Codable>: Codable, @unchecked Sendable {
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
