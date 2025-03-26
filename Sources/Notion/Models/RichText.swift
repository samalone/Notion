import Foundation
import SwiftyJSON

struct RichText: Codable, ExpressibleByStringLiteral {
    var json: JSON

    init(json: JSON) {
        self.json = json
    }

    init(stringLiteral value: StringLiteralType) {
        self.json = JSON(["type": "text", "text": ["content": value]])
    }

    init(from decoder: Decoder) throws {
        self.json = try JSON(from: decoder)
    }

    func encode(to encoder: Encoder) throws {
        try json.encode(to: encoder)
    }

    func italic() throws -> RichText {
        return RichText(json: try self.json.merged(with: JSON(["annotations": ["italic": true]])))
    }

    func bold() throws -> RichText {
        return RichText(json: try json.merged(with: JSON(["annotations": ["bold": true]])))
    }

    func color(_ color: Color) throws -> RichText {
        return RichText(json: try json.merged(with: JSON(["annotations": ["color": color.rawValue]])))
    }
}
