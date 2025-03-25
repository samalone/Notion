//
//  NotionAPIError.swift
//  Notion
//
//  Created by Stuart Malone on 3/25/25.
//



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
