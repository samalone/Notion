import Foundation

/// Represents a Notion block
public struct Block: NotionObject, Sendable, Codable {
    public let object: String
    public let id: String
    public let parent: Parent
    public let createdTime: Date
    public let lastEditedTime: Date
    public let createdBy: PartialUser
    public let lastEditedBy: PartialUser
    public let hasChildren: Bool
    public let archived: Bool
    public let type: BlockType
    
    // Single content property using enum with associated values
    public let content: BlockContent
    
    private enum CodingKeys: String, CodingKey {
        case object, id, parent, type, archived
        case hasChildren = "has_children"
        case createdTime = "created_time"
        case lastEditedTime = "last_edited_time"
        case createdBy = "created_by"
        case lastEditedBy = "last_edited_by"
        case paragraph, heading_1, heading_2, heading_3
        case bulleted_list_item, numbered_list_item, to_do, toggle
        case code, callout, quote, divider, image, video, file, bookmark
        case child_page
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        object = try container.decode(String.self, forKey: .object)
        id = try container.decode(String.self, forKey: .id)
        parent = try container.decode(Parent.self, forKey: .parent)
        hasChildren = try container.decode(Bool.self, forKey: .hasChildren)
        archived = try container.decode(Bool.self, forKey: .archived)
        type = try container.decode(BlockType.self, forKey: .type)
        
        // Parse dates
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let createdTimeString = try container.decode(String.self, forKey: .createdTime)
        createdTime = dateFormatter.date(from: createdTimeString) ?? Date()
        
        let lastEditedTimeString = try container.decode(String.self, forKey: .lastEditedTime)
        lastEditedTime = dateFormatter.date(from: lastEditedTimeString) ?? Date()
        
        createdBy = try container.decode(PartialUser.self, forKey: .createdBy)
        lastEditedBy = try container.decode(PartialUser.self, forKey: .lastEditedBy)
        
        // Decode block content based on type and assign to enum
        switch type {
        case .paragraph:
            content = .paragraph(try container.decode(ParagraphBlock.self, forKey: .paragraph))
        case .heading1:
            content = .heading1(try container.decode(HeadingBlock.self, forKey: .heading_1))
        case .heading2:
            content = .heading2(try container.decode(HeadingBlock.self, forKey: .heading_2))
        case .heading3:
            content = .heading3(try container.decode(HeadingBlock.self, forKey: .heading_3))
        case .bulletedListItem:
            content = .bulletedListItem(try container.decode(ListItemBlock.self, forKey: .bulleted_list_item))
        case .numberedListItem:
            content = .numberedListItem(try container.decode(ListItemBlock.self, forKey: .numbered_list_item))
        case .toDo:
            content = .toDo(try container.decode(ToDoBlock.self, forKey: .to_do))
        case .toggle:
            content = .toggle(try container.decode(ToggleBlock.self, forKey: .toggle))
        case .code:
            content = .code(try container.decode(CodeBlock.self, forKey: .code))
        case .callout:
            content = .callout(try container.decode(CalloutBlock.self, forKey: .callout))
        case .quote:
            content = .quote(try container.decode(QuoteBlock.self, forKey: .quote))
        case .divider:
            content = .divider(try container.decode(EmptyBlock.self, forKey: .divider))
        case .image:
            content = .image(try container.decode(FileBlock.self, forKey: .image))
        case .video:
            content = .video(try container.decode(FileBlock.self, forKey: .video))
        case .file:
            content = .file(try container.decode(FileBlock.self, forKey: .file))
        case .bookmark:
            content = .bookmark(try container.decode(BookmarkBlock.self, forKey: .bookmark))
        case .childPage:
            content = .childPage(try container.decode(ChildPageBlock.self, forKey: .child_page))
        default:
            content = .unsupported
        }
    }
    
    // Add custom encode(to:) method to handle the property name mismatch
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(object, forKey: .object)
        try container.encode(id, forKey: .id)
        try container.encode(parent, forKey: .parent)
        try container.encode(hasChildren, forKey: .hasChildren)
        try container.encode(archived, forKey: .archived)
        try container.encode(type, forKey: .type)
        
        // Format dates back to ISO8601 strings
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        try container.encode(dateFormatter.string(from: createdTime), forKey: .createdTime)
        try container.encode(dateFormatter.string(from: lastEditedTime), forKey: .lastEditedTime)
        try container.encode(createdBy, forKey: .createdBy)
        try container.encode(lastEditedBy, forKey: .lastEditedBy)
        
        // Encode the appropriate content based on block type
        switch content {
        case .paragraph(let value):
            try container.encode(value, forKey: .paragraph)
        case .heading1(let value):
            try container.encode(value, forKey: .heading_1)
        case .heading2(let value):
            try container.encode(value, forKey: .heading_2)
        case .heading3(let value):
            try container.encode(value, forKey: .heading_3)
        case .bulletedListItem(let value):
            try container.encode(value, forKey: .bulleted_list_item)
        case .numberedListItem(let value):
            try container.encode(value, forKey: .numbered_list_item)
        case .toDo(let value):
            try container.encode(value, forKey: .to_do)
        case .toggle(let value):
            try container.encode(value, forKey: .toggle)
        case .code(let value):
            try container.encode(value, forKey: .code)
        case .callout(let value):
            try container.encode(value, forKey: .callout)
        case .quote(let value):
            try container.encode(value, forKey: .quote)
        case .divider(let value):
            try container.encode(value, forKey: .divider)
        case .image(let value):
            try container.encode(value, forKey: .image)
        case .video(let value):
            try container.encode(value, forKey: .video)
        case .file(let value):
            try container.encode(value, forKey: .file)
        case .bookmark(let value):
            try container.encode(value, forKey: .bookmark)
        case .childPage(let value):
            try container.encode(value, forKey: .child_page)
        case .unsupported:
            break
        }
    }
}

/// Block content enum with associated values for each block type
public enum BlockContent: Sendable {
    case paragraph(ParagraphBlock)
    case heading1(HeadingBlock)
    case heading2(HeadingBlock)
    case heading3(HeadingBlock)
    case bulletedListItem(ListItemBlock)
    case numberedListItem(ListItemBlock)
    case toDo(ToDoBlock)
    case toggle(ToggleBlock)
    case code(CodeBlock)
    case callout(CalloutBlock)
    case quote(QuoteBlock)
    case divider(EmptyBlock)
    case image(FileBlock)
    case video(FileBlock)
    case file(FileBlock)
    case bookmark(BookmarkBlock)
    case childPage(ChildPageBlock)
    case unsupported
}

/// Block types supported by Notion
public enum BlockType: String, Sendable, Codable {
    case paragraph
    case heading1 = "heading_1"
    case heading2 = "heading_2"
    case heading3 = "heading_3"
    case bulletedListItem = "bulleted_list_item"
    case numberedListItem = "numbered_list_item"
    case toDo = "to_do"
    case toggle
    case code
    case callout
    case quote
    case divider
    case image
    case video
    case file
    case bookmark
    case childPage = "child_page"
    case unsupported
}

// MARK: - Block Content Types

/// Common properties across rich text blocks
public protocol RichTextBlockContent: Sendable, Codable {
    var richText: [RichText] { get }
    var color: String { get }
}

/// Paragraph block content
public struct ParagraphBlock: RichTextBlockContent, Sendable, Codable {
    public let richText: [RichText]
    public let color: String
    
    private enum CodingKeys: String, CodingKey {
        case richText = "rich_text"
        case color
    }
}

/// Heading block content
public struct HeadingBlock: RichTextBlockContent, Sendable, Codable {
    public let richText: [RichText]
    public let color: String
    public let isToggleable: Bool
    
    private enum CodingKeys: String, CodingKey {
        case richText = "rich_text"
        case color
        case isToggleable = "is_toggleable"
    }
}

/// List item block content
public struct ListItemBlock: RichTextBlockContent, Sendable, Codable {
    public let richText: [RichText]
    public let color: String
    
    private enum CodingKeys: String, CodingKey {
        case richText = "rich_text"
        case color
    }
}

/// To-do block content
public struct ToDoBlock: RichTextBlockContent, Sendable, Codable {
    public let richText: [RichText]
    public let color: String
    public let checked: Bool
    
    private enum CodingKeys: String, CodingKey {
        case richText = "rich_text"
        case color, checked
    }
}

/// Toggle block content
public struct ToggleBlock: RichTextBlockContent, Sendable, Codable {
    public let richText: [RichText]
    public let color: String
    
    private enum CodingKeys: String, CodingKey {
        case richText = "rich_text"
        case color
    }
}

/// Code block content
public struct CodeBlock: RichTextBlockContent, Sendable, Codable {
    public let richText: [RichText]
    public let color: String = "default" // Not actually in the API
    public let language: String
    public let caption: [RichText]?
    
    private enum CodingKeys: String, CodingKey {
        case richText = "rich_text"
        case language, caption
    }
}

/// Callout block content
public struct CalloutBlock: RichTextBlockContent, Sendable, Codable {
    public let richText: [RichText]
    public let color: String
    public let icon: Icon?
    
    private enum CodingKeys: String, CodingKey {
        case richText = "rich_text"
        case color, icon
    }
}

/// Quote block content
public struct QuoteBlock: RichTextBlockContent, Sendable, Codable {
    public let richText: [RichText]
    public let color: String
    
    private enum CodingKeys: String, CodingKey {
        case richText = "rich_text"
        case color
    }
}

/// Empty block like a divider
public struct EmptyBlock: Sendable, Codable {}

/// File-based block content
public struct FileBlock: Sendable, Codable {
    public let type: String
    public let caption: [RichText]?
    public let external: ExternalFile?
    public let file: File?
    
    private enum CodingKeys: String, CodingKey {
        case type, caption, external, file
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        type = try container.decode(String.self, forKey: .type)
        caption = try container.decodeIfPresent([RichText].self, forKey: .caption)
        
        if type == "external" {
            external = try container.decode(ExternalFile.self, forKey: .external)
            file = nil
        } else {
            file = try container.decode(File.self, forKey: .file)
            external = nil
        }
    }
}

/// Bookmark block content
public struct BookmarkBlock: Sendable, Codable {
    public let url: URL
    public let caption: [RichText]?
    
    private enum CodingKeys: String, CodingKey {
        case url, caption
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let urlString = try container.decode(String.self, forKey: .url)
        url = URL(string: urlString)!
        caption = try container.decodeIfPresent([RichText].self, forKey: .caption)
    }
}

/// Child page block content
public struct ChildPageBlock: Sendable, Codable {
    public let title: String
    
    private enum CodingKeys: String, CodingKey {
        case title
    }
}
