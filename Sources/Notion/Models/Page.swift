import Foundation
import SwiftyJSON

/// Represents a Notion page
public struct Page: Codable, Identifiable {
    var json: JSON

    init(json: JSON) {
        self.json = json
    }

    public init(from decoder: Decoder) throws {
        self.json = try JSON(from: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        try json.encode(to: encoder)
    }

    public var id: String {
        get {
            return json["id"].stringValue
        }
        set {
            json["id"].stringValue = newValue
        }
    }
}

// MARK: - Partial User

/// A simplified user reference
public struct PartialUser: NotionObject, Sendable, Codable {
    public let object: String
    public let id: String
}

// MARK: - Cover

/// Represents a page cover image
public struct Cover: Sendable, Codable {
    public enum CoverType: String, Sendable, Codable {
        case external
        case file
    }
    
    public let type: CoverType
    public let external: ExternalFile?
    public let file: File?
    
    private enum CodingKeys: String, CodingKey {
        case type, external, file
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(CoverType.self, forKey: .type)
        
        switch type {
        case .external:
            external = try container.decodeIfPresent(ExternalFile.self, forKey: .external)
            file = nil
        case .file:
            file = try container.decodeIfPresent(File.self, forKey: .file)
            external = nil
        }
    }
}

/// Represents an external file
public struct ExternalFile: Sendable, Codable {
    public let url: URL
    
    private enum CodingKeys: String, CodingKey {
        case url
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let urlString = try container.decode(String.self, forKey: .url)
        url = URL(string: urlString)!
    }
}

/// Represents a file hosted by Notion
public struct File: Sendable, Codable {
    public let url: URL
    public let expiryTime: Date?
    
    private enum CodingKeys: String, CodingKey {
        case url
        case expiryTime = "expiry_time"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let urlString = try container.decode(String.self, forKey: .url)
        url = URL(string: urlString)!
        
        if let expiryString = try container.decodeIfPresent(String.self, forKey: .expiryTime) {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            expiryTime = dateFormatter.date(from: expiryString)
        } else {
            expiryTime = nil
        }
    }
}

// MARK: - Icon

/// Represents a page icon
public struct Icon: Sendable, Codable {
    public enum IconType: String, Sendable, Codable {
        case emoji
        case external
        case file
    }
    
    public let type: IconType
    public let emoji: String?
    public let external: ExternalFile?
    public let file: File?
    
    private enum CodingKeys: String, CodingKey {
        case type, emoji, external, file
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(IconType.self, forKey: .type)
        
        switch type {
        case .emoji:
            emoji = try container.decodeIfPresent(String.self, forKey: .emoji)
            external = nil
            file = nil
        case .external:
            emoji = nil
            external = try container.decodeIfPresent(ExternalFile.self, forKey: .external)
            file = nil
        case .file:
            emoji = nil
            external = nil
            file = try container.decodeIfPresent(File.self, forKey: .file)
        }
    }
}

// MARK: - Parent

/// Represents a page parent reference
public struct Parent: Sendable, Codable {
    public enum ParentType: String, Sendable, Codable {
        case databaseId = "database_id"
        case pageId = "page_id"
        case workspace
    }
    
    public let type: ParentType
    public let databaseId: String?
    public let pageId: String?
    
    private enum CodingKeys: String, CodingKey {
        case type
        case databaseId = "database_id"
        case pageId = "page_id"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(ParentType.self, forKey: .type)
        
        switch type {
        case .databaseId:
            databaseId = try container.decode(String.self, forKey: .databaseId)
            pageId = nil
        case .pageId:
            databaseId = nil
            pageId = try container.decode(String.self, forKey: .pageId)
        case .workspace:
            databaseId = nil
            pageId = nil
        }
    }
}
