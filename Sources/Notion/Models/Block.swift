import Foundation
import SwiftyJSON

/// Represents a Notion block
/// This is such a complex type that we don't try to map it to a Swift type,
/// but instead we use SwiftyJSON to parse the JSON and provide access to the data.
public struct Block: Codable, Identifiable {
    var json: JSON

    init(json: JSON) {
        self.json = json
    }

    init(data: Data) throws {
        self.json = try JSON(data: data)
    }

    func data() throws -> Data {
        return try json.rawData()
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
        get {
            guard json["type"].stringValue == "child_page" else { return nil }
            return json["child_page"]["title"].stringValue
        }
        set {
            if let newValue {
                json["type"].stringValue = "child_page"
                json["child_page"]["title"].stringValue = newValue
            }
        }
    }

    static func paragraph(_ text: RichText, color: Color? = nil) -> Block {
        var json: JSON = [
            "object": "block", "type": "paragraph", "paragraph": ["rich_text": [text.json]],
        ]
        if let color = color {
            json["paragraph"]["color"].stringValue = color.rawValue
        }
        return Block(json: json)
    }

    static func paragraph(_ text: String, color: Color? = nil) -> Block {
        return paragraph(RichText(stringLiteral: text), color: color)
    }

    static func heading1(_ text: RichText, color: Color? = nil) -> Block {
        var json: JSON = [
            "object": "block", "type": "heading_1", "heading_1": ["rich_text": [text.json]],
        ]
        if let color = color {
            json["heading_1"]["color"].stringValue = color.rawValue
        }
        return Block(json: json)
    }

    static func heading1(_ text: String, color: Color? = nil) -> Block {
        return heading1(RichText(stringLiteral: text), color: color)
    }

    static func heading2(_ text: RichText, color: Color? = nil) -> Block {
        var json: JSON = [
            "object": "block", "type": "heading_2", "heading_2": ["rich_text": [text.json]],
        ]
        if let color = color {
            json["heading_2"]["color"].stringValue = color.rawValue
        }
        return Block(json: json)
    }

    static func heading2(_ text: String, color: Color? = nil) -> Block {
        return heading2(RichText(stringLiteral: text), color: color)
    }

    static func heading3(_ text: RichText, color: Color? = nil) -> Block {
        var json: JSON = [
            "object": "block", "type": "heading_3", "heading_3": ["rich_text": [text.json]],
        ]
        if let color = color {
            json["heading_3"]["color"].stringValue = color.rawValue
        }
        return Block(json: json)
    }

    static func heading3(_ text: String, color: Color? = nil) -> Block {
        return heading3(RichText(stringLiteral: text), color: color)
    }

    static func table(rows: [[RichText]], hasColumnHeader: Bool = false, hasRowHeader: Bool = false)
        -> Block
    {
        var rowsJson: [JSON] = []
        for row in rows {
            var rowJson: JSON = ["type": "table_row"]
            var cellsJson: [JSON] = []
            for cell in row {
                cellsJson.append([cell.json])
            }
            rowJson["table_row"] = JSON(["cells": cellsJson])
            rowsJson.append(rowJson)
        }
        var json: JSON = [
            "object": "block", "type": "table",
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
