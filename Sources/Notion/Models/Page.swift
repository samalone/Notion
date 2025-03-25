import Foundation

/// Represents a Notion page
public struct Page: NotionObject, Sendable, Codable {
    public let object: String
    public let id: String
    public let createdTime: Date
    public let lastEditedTime: Date
    public let createdBy: PartialUser
    public let lastEditedBy: PartialUser
    public let cover: Cover?
    public let icon: Icon?
    public let parent: Parent
    public let archived: Bool
    public let properties: [String: PageProperty]
    public let url: URL
    public let publicURL: URL?
    
    private enum CodingKeys: String, CodingKey {
        case object, id, cover, icon, parent, archived, properties, url
        case createdTime = "created_time"
        case lastEditedTime = "last_edited_time"
        case createdBy = "created_by"
        case lastEditedBy = "last_edited_by"
        case publicURL = "public_url"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        object = try container.decode(String.self, forKey: .object)
        id = try container.decode(String.self, forKey: .id)
        
        // Parse dates
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let createdTimeString = try container.decode(String.self, forKey: .createdTime)
        if let date = dateFormatter.date(from: createdTimeString) {
            createdTime = date
        } else {
            throw DecodingError.dataCorruptedError(forKey: .createdTime, in: container, debugDescription: "Invalid date format")
        }
        
        let lastEditedTimeString = try container.decode(String.self, forKey: .lastEditedTime)
        if let date = dateFormatter.date(from: lastEditedTimeString) {
            lastEditedTime = date
        } else {
            throw DecodingError.dataCorruptedError(forKey: .lastEditedTime, in: container, debugDescription: "Invalid date format")
        }
        
        createdBy = try container.decode(PartialUser.self, forKey: .createdBy)
        lastEditedBy = try container.decode(PartialUser.self, forKey: .lastEditedBy)
        cover = try container.decodeIfPresent(Cover.self, forKey: .cover)
        icon = try container.decodeIfPresent(Icon.self, forKey: .icon)
        parent = try container.decode(Parent.self, forKey: .parent)
        archived = try container.decode(Bool.self, forKey: .archived)
        properties = try container.decode([String: PageProperty].self, forKey: .properties)
        
        let urlString = try container.decode(String.self, forKey: .url)
        url = URL(string: urlString)!
        
        if let publicURLString = try container.decodeIfPresent(String.self, forKey: .publicURL),
           let publicURL = URL(string: publicURLString) {
            self.publicURL = publicURL
        } else {
            publicURL = nil
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
