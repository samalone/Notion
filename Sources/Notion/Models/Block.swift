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

    static func paragraph(_ text: String, color: Color? = nil) -> Block {
        var json: JSON = ["object": "block", "type": "paragraph", "paragraph": ["rich_text": [["type": "text", "text": ["content": text]]]]]
        if let color = color {
            json["paragraph"]["color"].stringValue = color.rawValue
        }
        return Block(json: json)
    }

    static func heading1(_ text: String, color: Color? = nil) -> Block {
        var json: JSON = ["object": "block", "type": "heading_1", "heading_1": ["rich_text": [["type": "text", "text": ["content": text]]]]]
        if let color = color {
            json["heading_1"]["color"].stringValue = color.rawValue
        }
        return Block(json: json)
    }

    static func heading2(_ text: String, color: Color? = nil) -> Block {
        var json: JSON = ["object": "block", "type": "heading_2", "heading_2": ["rich_text": [["type": "text", "text": ["content": text]]]]]
        if let color = color {
            json["heading_2"]["color"].stringValue = color.rawValue
        }
        return Block(json: json)
    }

    static func heading3(_ text: String, color: Color? = nil) -> Block {
        var json: JSON = ["object": "block", "type": "heading_3", "heading_3": ["rich_text": [["type": "text", "text": ["content": text]]]]]
        if let color = color {
            json["heading_3"]["color"].stringValue = color.rawValue
        }
        return Block(json: json)
    }
}
