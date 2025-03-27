import Foundation
import SwiftyJSON

public struct RichText: Codable, Sendable, ExpressibleByStringLiteral {
    var json: JSON

    init(json: JSON) {
        self.json = json
    }

    public init(_ text: String) {
        self.json = ["type": "text", "text": ["content": text]]
    }

    public init(stringLiteral value: StringLiteralType) {
        self.json = ["type": "text", "text": ["content": value]]
    }

    public init(from decoder: Decoder) throws {
        self.json = try JSON(from: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        try json.encode(to: encoder)
    }

    func italic() throws -> RichText {
        return RichText(json: self.json.merging(["annotations": ["italic": true]]))
    }

    func bold() throws -> RichText {
        return RichText(json: json.merging(["annotations": ["bold": true]]))
    }

    func color(_ color: Color) throws -> RichText {
        return RichText(json: json.merging(["annotations": ["color": color.rawValue]]))
    }
}
