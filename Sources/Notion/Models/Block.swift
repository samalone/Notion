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
    
    // Block content based on type
    public let paragraph: ParagraphBlock?
    public let heading1: HeadingBlock?
    public let heading2: HeadingBlock?
    public let heading3: HeadingBlock?
    public let bulletedListItem: ListItemBlock?
    public let numberedListItem: ListItemBlock?
    public let toDo: ToDoBlock?
    public let toggle: ToggleBlock?
    public let code: CodeBlock?
    public let callout: CalloutBlock?
    public let quote: QuoteBlock?
    public let divider: EmptyBlock?
    public let image: FileBlock?
    public let video: FileBlock?
    public let file: FileBlock?
    public let bookmark: BookmarkBlock?
    public let childPage: ChildPageBlock?
    
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
        
        // Decode block content based on type
        switch type {
        case .paragraph:
            paragraph = try container.decodeIfPresent(ParagraphBlock.self, forKey: .paragraph)
            heading1 = nil; heading2 = nil; heading3 = nil; bulletedListItem = nil
            numberedListItem = nil; toDo = nil; toggle = nil; code = nil; callout = nil
            quote = nil; divider = nil; image = nil; video = nil; file = nil; bookmark = nil; childPage = nil
        case .heading1:
            heading1 = try container.decodeIfPresent(HeadingBlock.self, forKey: .heading_1)
            paragraph = nil; heading2 = nil; heading3 = nil; bulletedListItem = nil
            numberedListItem = nil; toDo = nil; toggle = nil; code = nil; callout = nil
            quote = nil; divider = nil; image = nil; video = nil; file = nil; bookmark = nil; childPage = nil
        case .heading2:
            heading2 = try container.decodeIfPresent(HeadingBlock.self, forKey: .heading_2)
            paragraph = nil; heading1 = nil; heading3 = nil; bulletedListItem = nil
            numberedListItem = nil; toDo = nil; toggle = nil; code = nil; callout = nil
            quote = nil; divider = nil; image = nil; video = nil; file = nil; bookmark = nil; childPage = nil
        case .heading3:
            heading3 = try container.decodeIfPresent(HeadingBlock.self, forKey: .heading_3)
            paragraph = nil; heading1 = nil; heading2 = nil; bulletedListItem = nil
            numberedListItem = nil; toDo = nil; toggle = nil; code = nil; callout = nil
            quote = nil; divider = nil; image = nil; video = nil; file = nil; bookmark = nil; childPage = nil
        case .bulletedListItem:
            bulletedListItem = try container.decodeIfPresent(ListItemBlock.self, forKey: .bulleted_list_item)
            paragraph = nil; heading1 = nil; heading2 = nil; heading3 = nil
            numberedListItem = nil; toDo = nil; toggle = nil; code = nil; callout = nil
            quote = nil; divider = nil; image = nil; video = nil; file = nil; bookmark = nil; childPage = nil
        case .numberedListItem:
            numberedListItem = try container.decodeIfPresent(ListItemBlock.self, forKey: .numbered_list_item)
            paragraph = nil; heading1 = nil; heading2 = nil; heading3 = nil; bulletedListItem = nil
            toDo = nil; toggle = nil; code = nil; callout = nil
            quote = nil; divider = nil; image = nil; video = nil; file = nil; bookmark = nil; childPage = nil
        case .toDo:
            toDo = try container.decodeIfPresent(ToDoBlock.self, forKey: .to_do)
            paragraph = nil; heading1 = nil; heading2 = nil; heading3 = nil; bulletedListItem = nil
            numberedListItem = nil; toggle = nil; code = nil; callout = nil
            quote = nil; divider = nil; image = nil; video = nil; file = nil; bookmark = nil; childPage = nil
        case .toggle:
            toggle = try container.decodeIfPresent(ToggleBlock.self, forKey: .toggle)
            paragraph = nil; heading1 = nil; heading2 = nil; heading3 = nil; bulletedListItem = nil
            numberedListItem = nil; toDo = nil; code = nil; callout = nil
            quote = nil; divider = nil; image = nil; video = nil; file = nil; bookmark = nil; childPage = nil
        case .code:
            code = try container.decodeIfPresent(CodeBlock.self, forKey: .code)
            paragraph = nil; heading1 = nil; heading2 = nil; heading3 = nil; bulletedListItem = nil
            numberedListItem = nil; toDo = nil; toggle = nil; callout = nil
            quote = nil; divider = nil; image = nil; video = nil; file = nil; bookmark = nil; childPage = nil
        case .callout:
            callout = try container.decodeIfPresent(CalloutBlock.self, forKey: .callout)
            paragraph = nil; heading1 = nil; heading2 = nil; heading3 = nil; bulletedListItem = nil
            numberedListItem = nil; toDo = nil; toggle = nil; code = nil
            quote = nil; divider = nil; image = nil; video = nil; file = nil; bookmark = nil; childPage = nil
        case .quote:
            quote = try container.decodeIfPresent(QuoteBlock.self, forKey: .quote)
            paragraph = nil; heading1 = nil; heading2 = nil; heading3 = nil; bulletedListItem = nil
            numberedListItem = nil; toDo = nil; toggle = nil; code = nil; callout = nil
            divider = nil; image = nil; video = nil; file = nil; bookmark = nil; childPage = nil
        case .divider:
            divider = try container.decodeIfPresent(EmptyBlock.self, forKey: .divider)
            paragraph = nil; heading1 = nil; heading2 = nil; heading3 = nil; bulletedListItem = nil
            numberedListItem = nil; toDo = nil; toggle = nil; code = nil; callout = nil
            quote = nil; image = nil; video = nil; file = nil; bookmark = nil; childPage = nil
        case .image:
            image = try container.decodeIfPresent(FileBlock.self, forKey: .image)
            paragraph = nil; heading1 = nil; heading2 = nil; heading3 = nil; bulletedListItem = nil
            numberedListItem = nil; toDo = nil; toggle = nil; code = nil; callout = nil
            quote = nil; divider = nil; video = nil; file = nil; bookmark = nil; childPage = nil
        case .video:
            video = try container.decodeIfPresent(FileBlock.self, forKey: .video)
            paragraph = nil; heading1 = nil; heading2 = nil; heading3 = nil; bulletedListItem = nil
            numberedListItem = nil; toDo = nil; toggle = nil; code = nil; callout = nil
            quote = nil; divider = nil; image = nil; file = nil; bookmark = nil; childPage = nil
        case .file:
            file = try container.decodeIfPresent(FileBlock.self, forKey: .file)
            paragraph = nil; heading1 = nil; heading2 = nil; heading3 = nil; bulletedListItem = nil
            numberedListItem = nil; toDo = nil; toggle = nil; code = nil; callout = nil
            quote = nil; divider = nil; image = nil; video = nil; bookmark = nil; childPage = nil
        case .bookmark:
            bookmark = try container.decodeIfPresent(BookmarkBlock.self, forKey: .bookmark)
            paragraph = nil; heading1 = nil; heading2 = nil; heading3 = nil; bulletedListItem = nil
            numberedListItem = nil; toDo = nil; toggle = nil; code = nil; callout = nil
            quote = nil; divider = nil; image = nil; video = nil; file = nil; childPage = nil
        case .childPage:
            childPage = try container.decodeIfPresent(ChildPageBlock.self, forKey: .child_page)
            paragraph = nil; heading1 = nil; heading2 = nil; heading3 = nil; bulletedListItem = nil
            numberedListItem = nil; toDo = nil; toggle = nil; code = nil; callout = nil
            quote = nil; divider = nil; image = nil; video = nil; file = nil; bookmark = nil
        default:
            paragraph = nil; heading1 = nil; heading2 = nil; heading3 = nil; bulletedListItem = nil
            numberedListItem = nil; toDo = nil; toggle = nil; code = nil; callout = nil
            quote = nil; divider = nil; image = nil; video = nil; file = nil; bookmark = nil; childPage = nil
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
        switch type {
        case .paragraph:
            if let paragraph = paragraph {
                try container.encode(paragraph, forKey: .paragraph)
            }
        case .heading1:
            if let heading1 = heading1 {
                try container.encode(heading1, forKey: .heading_1)
            }
        case .heading2:
            if let heading2 = heading2 {
                try container.encode(heading2, forKey: .heading_2)
            }
        case .heading3:
            if let heading3 = heading3 {
                try container.encode(heading3, forKey: .heading_3)
            }
        case .bulletedListItem:
            if let bulletedListItem = bulletedListItem {
                try container.encode(bulletedListItem, forKey: .bulleted_list_item)
            }
        case .numberedListItem:
            if let numberedListItem = numberedListItem {
                try container.encode(numberedListItem, forKey: .numbered_list_item)
            }
        case .toDo:
            if let toDo = toDo {
                try container.encode(toDo, forKey: .to_do)
            }
        case .toggle:
            if let toggle = toggle {
                try container.encode(toggle, forKey: .toggle)
            }
        case .code:
            if let code = code {
                try container.encode(code, forKey: .code)
            }
        case .callout:
            if let callout = callout {
                try container.encode(callout, forKey: .callout)
            }
        case .quote:
            if let quote = quote {
                try container.encode(quote, forKey: .quote)
            }
        case .divider:
            if let divider = divider {
                try container.encode(divider, forKey: .divider)
            }
        case .image:
            if let image = image {
                try container.encode(image, forKey: .image)
            }
        case .video:
            if let video = video {
                try container.encode(video, forKey: .video)
            }
        case .file:
            if let file = file {
                try container.encode(file, forKey: .file)
            }
        case .bookmark:
            if let bookmark = bookmark {
                try container.encode(bookmark, forKey: .bookmark)
            }
        case .childPage:
            if let childPage = childPage {
                try container.encode(childPage, forKey: .child_page)
            }
        default:
            break
        }
    }
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
