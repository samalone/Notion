import Foundation

/// Represents a page property
public struct PageProperty: Sendable, Codable {
    public let id: String
    public let type: PropertyType
    
    // Property type-specific fields
    public let title: [RichText]?
    public let richText: [RichText]?
    public let number: Double?
    public let select: Option?
    public let multiSelect: [Option]?
    public let date: DateProperty?
    public let formula: Formula?
    public let relation: [RelationReference]?
    public let rollup: Rollup?
    public let people: [User]?
    public let files: [FileReference]?
    public let checkbox: Bool?
    public let url: URL?
    public let email: String?
    public let phoneNumber: String?
    public let createdTime: Date?
    public let createdBy: PartialUser?
    public let lastEditedTime: Date?
    public let lastEditedBy: PartialUser?
    
    private enum CodingKeys: String, CodingKey {
        case id, type
        case title, number, select, date, formula, relation, rollup, people, files, checkbox, url, email
        case richText = "rich_text"
        case multiSelect = "multi_select"
        case phoneNumber = "phone_number"
        case createdTime = "created_time"
        case createdBy = "created_by"
        case lastEditedTime = "last_edited_time"
        case lastEditedBy = "last_edited_by"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(PropertyType.self, forKey: .type)
        
        // Initialize properties conditionally based on type
        // Default all to nil
        title = type == .title ? try container.decode([RichText].self, forKey: .title) : nil
        richText = type == .richText ? try container.decode([RichText].self, forKey: .richText) : nil
        number = type == .number ? try container.decode(Double.self, forKey: .number) : nil
        select = type == .select ? try container.decode(Option.self, forKey: .select) : nil
        multiSelect = type == .multiSelect ? try container.decode([Option].self, forKey: .multiSelect) : nil
        date = type == .date ? try container.decode(DateProperty.self, forKey: .date) : nil
        formula = type == .formula ? try container.decode(Formula.self, forKey: .formula) : nil
        relation = type == .relation ? try container.decode([RelationReference].self, forKey: .relation) : nil
        rollup = type == .rollup ? try container.decode(Rollup.self, forKey: .rollup) : nil
        people = type == .people ? try container.decode([User].self, forKey: .people) : nil
        files = type == .files ? try container.decode([FileReference].self, forKey: .files) : nil
        checkbox = type == .checkbox ? try container.decode(Bool.self, forKey: .checkbox) : nil
        
        // Handle URL type specially to handle empty strings
        if type == .url {
            let urlString = try container.decode(String.self, forKey: .url)
            url = !urlString.isEmpty ? URL(string: urlString) : nil
        } else {
            url = nil
        }
        
        email = type == .email ? try container.decode(String.self, forKey: .email) : nil
        phoneNumber = type == .phoneNumber ? try container.decode(String.self, forKey: .phoneNumber) : nil
        
        // Handle date fields with special parsing
        if type == .createdTime {
            let createdTimeString = try container.decode(String.self, forKey: .createdTime)
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            createdTime = dateFormatter.date(from: createdTimeString)
        } else {
            createdTime = nil
        }
        
        createdBy = type == .createdBy ? try container.decode(PartialUser.self, forKey: .createdBy) : nil
        
        if type == .lastEditedTime {
            let lastEditedTimeString = try container.decode(String.self, forKey: .lastEditedTime)
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            lastEditedTime = dateFormatter.date(from: lastEditedTimeString)
        } else {
            lastEditedTime = nil
        }
        
        lastEditedBy = type == .lastEditedBy ? try container.decode(PartialUser.self, forKey: .lastEditedBy) : nil
    }
}

/// Property types supported by Notion
public enum PropertyType: String, Sendable, Codable {
    case title
    case richText = "rich_text"
    case number
    case select
    case multiSelect = "multi_select"
    case date
    case formula
    case relation
    case rollup
    case people
    case files
    case checkbox
    case url
    case email
    case phoneNumber = "phone_number"
    case createdTime = "created_time"
    case createdBy = "created_by"
    case lastEditedTime = "last_edited_time"
    case lastEditedBy = "last_edited_by"
}

// MARK: - Rich Text

/// Represents rich text content
public struct RichText: Sendable, Codable {
    public enum RichTextType: String, Sendable, Codable {
        case text
        case mention
        case equation
    }
    
    public let type: RichTextType
    public let text: TextContent?
    public let annotations: Annotations
    public let plainText: String
    public let href: URL?
    
    private enum CodingKeys: String, CodingKey {
        case type, text, annotations
        case plainText = "plain_text"
        case href
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        type = try container.decode(RichTextType.self, forKey: .type)
        annotations = try container.decode(Annotations.self, forKey: .annotations)
        plainText = try container.decode(String.self, forKey: .plainText)
        
        if let hrefString = try container.decodeIfPresent(String.self, forKey: .href) {
            href = URL(string: hrefString)
        } else {
            href = nil
        }
        
        // Add content based on type
        switch type {
        case .text:
            text = try container.decode(TextContent.self, forKey: .text)
        default:
            text = nil
            // For simplicity, we're only implementing text type right now
            // Additional types could be added as needed
        }
    }
}

/// Text content within rich text
public struct TextContent: Sendable, Codable {
    public let content: String
    public let link: Link?
}

/// Link within text content
public struct Link: Sendable, Codable {
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

/// Text annotations
public struct Annotations: Sendable, Codable {
    public let bold: Bool
    public let italic: Bool
    public let strikethrough: Bool
    public let underline: Bool
    public let code: Bool
    public let color: String
}

// MARK: - Options

/// Represents a select option
public struct Option: Sendable, Codable {
    public let id: String
    public let name: String
    public let color: String
}

// MARK: - Date Property

/// Date property
public struct DateProperty: Sendable, Codable {
    public let start: String
    public let end: String?
    public let timeZone: String?
    
    private enum CodingKeys: String, CodingKey {
        case start, end
        case timeZone = "time_zone"
    }
}

// MARK: - Formula

/// Formula property
public struct Formula: Sendable, Codable {
    public enum FormulaType: String, Sendable, Codable {
        case string
        case number
        case boolean
        case date
    }
    
    public let type: FormulaType
    public let string: String?
    public let number: Double?
    public let boolean: Bool?
    public let date: DateProperty?
}

// MARK: - Relation

/// Relation reference
public struct RelationReference: Sendable, Codable {
    public let id: String
}

// MARK: - Rollup

/// Rollup property
public struct Rollup: Sendable, Codable {
    public enum RollupType: String, Sendable, Codable {
        case number
        case date
        case array
    }
    
    public let type: RollupType
    public let number: Double?
    public let date: DateProperty?
    public let function: String
    
    // Array type isn't fully implemented as it's more complex
}

// MARK: - File Reference

/// File reference
public struct FileReference: Sendable, Codable {
    public enum FileType: String, Sendable, Codable {
        case external
        case file
    }
    
    public let name: String
    public let type: FileType
    public let external: ExternalFile?
    public let file: File?
    
    private enum CodingKeys: String, CodingKey {
        case name, type, external, file
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(FileType.self, forKey: .type)
        
        switch type {
        case .external:
            external = try container.decode(ExternalFile.self, forKey: .external)
            file = nil
        case .file:
            external = nil
            file = try container.decode(File.self, forKey: .file)
        }
    }
}
