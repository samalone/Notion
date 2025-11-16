import Foundation

// The goal of this library is to create a general-purpose JSON representation
// that is `Sendable` and `Codable`. This allows for easy serialization and
// deserialization of JSON data in Swift, and allows JSON data structures to
// be sent between actors.

public protocol JSONType: Sendable, Codable {
    // This protocol is a marker protocol that indicates that a type is JSON.
    // It is empty because it is only used for type checking.
}

extension Dictionary: JSONType where Key == String, Value: JSONType {
    // A dictionary is JSON if its keys are strings and its values are JSON.
}

extension Array: JSONType where Element: JSONType {
    // An array is JSON if its elements are JSON.
}

extension String: JSONType {
    // A string is JSON.
}

extension Int: JSONType {
    // An integer is JSON.
}

extension Double: JSONType {
    // A double is JSON.
}

extension Bool: JSONType {
    // A boolean is JSON.
}

extension Optional: JSONType where Wrapped: JSONType {
    // An optional is JSON if its wrapped type is JSON.
}

// To allow subscripting both dictionaries and arrays, we need to define a
// protocol that allows for subscripting with both strings and integers.
public enum JSONSubscript {
    // A type that can be used to subscript JSON values.
    case key(String)
    case index(Int)
}

extension JSONSubscript: ExpressibleByStringLiteral, ExpressibleByIntegerLiteral {
    // Allow JSONSubscript to be created from string and integer literals.
    public init(stringLiteral value: String) {
        self = .key(value)
    }

    public init(integerLiteral value: Int) {
        self = .index(value)
    }
}

// The JSON enum represents a JSON value. It can be a string, integer, double,
// boolean, array, dictionary, or null value. It conforms to JSONType, which
// allows it to be used in place of any JSON value. It also conforms to
// ExpressibleByArrayLiteral and ExpressibleByDictionaryLiteral, which allows
// for easy initialization of JSON arrays and dictionaries.

public enum JSON: JSONType, ExpressibleByArrayLiteral, ExpressibleByDictionaryLiteral {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([JSON])
    case dictionary([String: JSON])
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode([String: JSON].self) {
            self = .dictionary(value)
        } else if let value = try? container.decode([JSON].self) {
            self = .array(value)
        } else if container.decodeNil() {
            self = .null
        } else {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Invalid JSON value")
        }
    }

    public init(_ value: [String: JSONType]) {
        self = .dictionary(value.mapValues { JSON.wrap($0) })
    }

    public init(_ value: [JSONType]) {
        self = .array(value.map { JSON.wrap($0) })
    }

    public init(data: Data) throws {
        self = try JSONDecoder().decode(JSON.self, from: data)
    }

    public init(arrayLiteral elements: Any...) {
        self = .array(elements.map { JSON.wrap($0) })
    }

    // For ease-of-use, we need to accept dictionary literals of type [String: Any],
    // which is what Swift creates when the values are of different types.
    // This constructor will fail if the values are not JSONType.
    public init(dictionaryLiteral elements: (String, Any)...) {
        self = .dictionary(Dictionary(uniqueKeysWithValues: elements.map { ($0.0, JSON.wrap($0.1)) }))
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .string(let value):
            try value.encode(to: encoder)
        case .int(let value):
            try value.encode(to: encoder)
        case .double(let value):
            try value.encode(to: encoder)
        case .bool(let value):
            try value.encode(to: encoder)
        case .array(let value):
            try value.encode(to: encoder)
        case .dictionary(let value):
            try value.encode(to: encoder)
        case .null:
            var container = encoder.singleValueContainer()
            try container.encodeNil()
        }
    }

    public func data() throws -> Data {
        try JSONEncoder().encode(self)
    }

    public static func wrap(_ value: Any) -> JSON {
        switch value {
        case let value as JSON:
            return value
        case let value as String:
            return .string(value)
        case let value as Int:
            return .int(value)
        case let value as Double:
            return .double(value)
        case let value as Bool:
            return .bool(value)
        case let value as [JSON]:
            return .array(value)
        case let value as [String: JSON]:
            return .dictionary(value)
        case let value as [String: Any]:
            return .dictionary(value.mapValues { JSON.wrap($0) })
        case let value as [Any]:
            return .array(value.map { JSON.wrap($0) })
        default:
            fatalError("Unsupported JSON type: \(type(of: value))")
        }
    }

    public var stringValue: String {
        switch self {
        case .string(let value):
            return value
        case .int(let value):
            return String(value)
        case .double(let value):
            return String(value)
        case .bool(let value):
            return String(value)
        case .array, .dictionary, .null:
            return ""
        }
    }

    public var arrayValue: [JSON] {
        if case .array(let value) = self {
            return value
        }
        return []
    }

    public var boolValue: Bool {
        if case .bool(let value) = self {
            return value
        }
        return false
    }

    public var intValue: Int {
        switch self {
        case .int(let value):
            return value
        case .double(let value):
            return Int(value)
        default:
            return 0
        }
    }

    public var doubleValue: Double {
        switch self {
        case .double(let value):
            return value
        case .int(let value):
            return Double(value)
        default:
            return 0.0
        }
    }

    public var dictionaryValue: [String: JSON] {
        if case .dictionary(let value) = self {
            return value
        }
        return [:]
    }

    public var isNull: Bool {
        if case .null = self {
            return true
        }
        return false
    }

    public func merging(_ other: JSON) -> JSON {
        switch (self, other) {
        case (.dictionary(let dict1), .dictionary(let dict2)):
            var result = dict1
            for (key, value) in dict2 {
                if let existingValue = dict1[key] {
                    result[key] = existingValue.merging(value)
                } else {
                    result[key] = value
                }
            }
            return .dictionary(result)
        case (.array(let array1), .array(let array2)):
            return .array(array1 + array2)
        default:
            return JSON.wrap(other)
        }
    }

    public func merging(_ other: JSONType) -> JSON {
        merging(JSON.wrap(other))
    }

    public subscript(key: String) -> JSON {
        if case .dictionary(let dict) = self {
            return dict[key] ?? .null
        }
        return .null
    }

    public subscript(index: Int) -> JSON {
        if case .array(let array) = self {
            return index < array.count ? array[index] : .null
        }
        return .null
    }

    public subscript(subscript: JSONSubscript) -> JSON {
        switch `subscript` {
        case .key(let key):
            return self[key]
        case .index(let index):
            return self[index]
        }
    }

    // Allow subscripting using an array of JSONSubscript values.
    public subscript(subscripts: JSONSubscript...) -> JSON {
        var json = self
        for `subscript` in subscripts {
            json = json[`subscript`]
        }
        return json
    }
}

public extension JSONType {
    // A JSON value can be encoded to a data object.
    func encode() throws -> Data {
        try JSONEncoder().encode(self)
    }

    // A JSON value can be decoded from a data object.
    static func decode(from data: Data) throws -> Self {
        try JSONDecoder().decode(Self.self, from: data)
    }
}

public extension Encodable {
    var prettyPrinted: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(self),
              let string = String(data: data, encoding: .utf8)
        else {
            return ""
        }
        return string
    }
}
