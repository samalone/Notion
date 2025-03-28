import Foundation

/// Represents a Notion block
public struct Block: Codable, Sendable, Identifiable {
    public var json: JSON

    init(json: JSON) {
        self.json = json
    }

    init(data: Data) throws {
        self.json = try JSON(data: data)
    }

    func data() throws -> Data {
        return try json.data()
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
    }

    public var object: String {
        json["object"].stringValue
    }

    public var type: String {
        json["type"].stringValue
    }

    // This is just a shortcut for json[json["type"].stringValue], which is where
    // Notion keeps the actual block content.
    public var content: JSON {
        json[type]
    }

    public var childPageTitle: String? {
            guard json["type"].stringValue == "child_page" else { return nil }
            return json["child_page"]["title"].stringValue
    }

    public static func paragraph(_ text: RichText, color: Color? = nil) -> Block {
        var json: JSON = [
            "object": "block", "type": "paragraph", "paragraph": ["rich_text": [text.json]],
        ]
        if let color = color {
            json = json.merging(["paragraph": ["color": color.rawValue]])
        }
        return Block(json: json)
    }

    public static func paragraph(_ text: String, color: Color? = nil) -> Block {
        return paragraph(RichText(stringLiteral: text), color: color)
    }

    public static func heading1(_ text: RichText, color: Color? = nil) -> Block {
        var json: JSON = [
            "object": "block", "type": "heading_1", "heading_1": ["rich_text": [text.json]],
        ]
        if let color = color {
            json = json.merging(["heading_1": ["color": color.rawValue]])
        }
        return Block(json: json)
    }

    public static func heading1(_ text: String, color: Color? = nil) -> Block {
        return heading1(RichText(stringLiteral: text), color: color)
    }

    public static func heading2(_ text: RichText, color: Color? = nil) -> Block {
        var json: JSON = [
            "object": "block", "type": "heading_2", "heading_2": ["rich_text": [text.json]],
        ]
        if let color = color {
            json = json.merging(["heading_2": ["color": color.rawValue]])
        }
        return Block(json: json)
    }

    public static func heading2(_ text: String, color: Color? = nil) -> Block {
        return heading2(RichText(stringLiteral: text), color: color)
    }

    public static func heading3(_ text: RichText, color: Color? = nil) -> Block {
        var json: JSON = [
            "object": "block", "type": "heading_3", "heading_3": ["rich_text": [text.json]],
        ]
        if let color = color {
            json = json.merging(["heading_3": ["color": color.rawValue]])
        }
        return Block(json: json)
    }

    public static func heading3(_ text: String, color: Color? = nil) -> Block {
        return heading3(RichText(stringLiteral: text), color: color)
    }

    public static func table(rows: [[RichText]], hasColumnHeader: Bool = false, hasRowHeader: Bool = false)
        -> Block
    {
        var rowsJson: [JSON] = []
        for row in rows {
            var rowJson: JSON = ["type": "table_row"]
            var cellsJson: [JSON] = []
            for cell in row {
                cellsJson.append([cell.json])
            }
            rowJson = rowJson.merging(["table_row": ["cells": cellsJson]])
            rowsJson.append(rowJson)
        }
        let json: JSON = [
            "object": "block",
            "type": "table",
            "table": [
                "table_width": rows[0].count,
                "has_column_header": hasColumnHeader,
                "has_row_header": hasRowHeader,
                "children": JSON(rowsJson),
            ],
        ]
        return Block(json: json)
    }
}
