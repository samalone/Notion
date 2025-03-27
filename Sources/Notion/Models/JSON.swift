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

struct JSONNull: JSONType {
    // A JSON null value that represents the literal "null" in JSON.

    // Singleton instance for efficiency
    static let null = JSONNull()

    // Custom encoding to ensure it's encoded as the literal "null" in JSON
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }

    // No custom init(from:) needed - Swift's decoder automatically handles this
    // when decodeNil() is true in the JSON struct's initializer
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

// To represent arbitrary JSON values, we also need a type-erased JSON type.
// This type is a JSON value that can be any JSON type, and it can be used to
// represent JSON values of unknown type.

public struct JSON: JSONType, ExpressibleByArrayLiteral, ExpressibleByDictionaryLiteral {
    // A type-erased JSON value.
    private let value: JSONType

    // Clients should use JSON.wrap() instead of calling this constructor directly.
    private init(_ value: JSONType) {
        self.value = value
    }

    static func wrap(_ value: Any) -> JSON {
        switch value {
        case let value as JSON:
            return value
        case let value as JSONType:
            return JSON(value)
        case let value as [Any]:
            return JSON(value.map { JSON.wrap($0) })
        case let value as [String: Any]:
            return JSON(value.mapValues { JSON.wrap($0) })
        default:
            fatalError("Unsupported JSON type: \(type(of: value))")
        }
    }

    // Add explicit initializers for collections of JSONType
    public init(_ value: [String: JSONType]) {
        // Wrap each value in the dictionary with JSON to handle existential types
        let wrappedDict = value.mapValues { JSON.wrap($0) }
        self.value = wrappedDict
    }

    public init(_ value: [JSONType]) {
        // Wrap each element in the array with JSON to handle existential types
        let wrappedArray = value.map { JSON.wrap($0) }
        self.value = wrappedArray
    }

    public init(data: Data) throws {
        self.value = try JSONDecoder().decode(JSON.self, from: data).value
    }

    public init(arrayLiteral elements: JSONType...) {
        self.value = elements.map { JSON.wrap($0) }
    }

    // public init(dictionaryLiteral elements: (String, JSONType)...) {
    //     self.value = Dictionary(uniqueKeysWithValues: elements.map {($0.0, JSON($0.1))})
    // }

    // For ease-of-use, we need to accept dictionary literals of type [String: Any],
    // which is what Swift creates when the values are of different types.
    // This constructor will fail if the values are not JSONType.
    public init(dictionaryLiteral elements: (String, Any)...) {
        self.value = Dictionary(uniqueKeysWithValues: elements.map { ($0.0, JSON.wrap($0.1)) })
    }

    public func data() throws -> Data {
        try JSONEncoder().encode(self)
    }

    public func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }

    public var stringValue: String {
        (value as? String) ?? (value as? Int).map { String($0) } ?? (value as? Double).map {
            String($0)
        } ?? (value as? Bool).map { String($0) } ?? ""
    }

    public var arrayValue: [JSON] {
        (value as? [JSON]) ?? []
    }

    public var boolValue: Bool {
        (value as? Bool) ?? false
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self.value = value
        } else if let value = try? container.decode(Int.self) {
            self.value = value
        } else if let value = try? container.decode(Double.self) {
            self.value = value
        } else if let value = try? container.decode(Bool.self) {
            self.value = value
        } else if let value = try? container.decode([String: JSON].self) {
            self.value = value
        } else if let value = try? container.decode([JSON].self) {
            self.value = value
        } else if container.decodeNil() {
            // When the JSON contains "null", container.decodeNil() returns true
            // and we use the singleton instance
            self.value = JSONNull.null
        } else {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Invalid JSON value")
        }
    }

    public func merging(_ b: JSONType) -> JSON {
        JSON.wrap(value.merging(b))
    }

    public var isNull: Bool {
        value is JSONNull
    }

    // Helper method to create JSON null value
    public static var null: JSON {
        JSON(JSONNull.null)
    }

    // Subscript to access nested JSON values.
    // Returns JSON.null if the value is not found.
    public subscript(key: String) -> JSON {
        // First, try the direct [String: JSON] case which is most common
        if let dict = value as? [String: JSON] {
            return dict[key] ?? JSON.null
        }

        // If the above fails, check if we have a dictionary of a different type
        // that conforms to JSONType, and extract the value
        if let dict = value as? [String: JSONType] {
            if let nestedValue = dict[key] {
                return JSON.wrap(nestedValue)
            }
        }

        return JSON.null
    }

    public subscript(index: Int) -> JSON {
        // Similar approach for arrays
        if let array = value as? [JSON] {
            return index < array.count ? array[index] : JSON.null
        }

        if let array = value as? [JSONType] {
            if index < array.count {
                return JSON.wrap(array[index])
            }
        }

        return JSON.null
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

public extension JSONType {
    func merging(_ b: JSONType) -> JSONType {
        // Merge two JSON values.
        // If the values are dictionaries, recursively merge the dictionaries.
        // If the values are arrays, concatenate the arrays.
        // If either value is null, return the other value.
        // If the values are scalars, return the second value.
        // If the values are different types, return the second value.
        if self is JSONNull {
            return b
        } else if b is JSONNull {
            return self
        } else if let dict1 = self as? [String: JSONType], let dict2 = b as? [String: JSONType] {
            let mergedDict = dict1.merging(dict2, uniquingKeysWith: { $0.merging($1) })
            return JSON(mergedDict)
        } else if let array1 = self as? [JSONType], let array2 = b as? [JSONType] {
            let combinedArray = array1 + array2
            return JSON(combinedArray)
        } else {
            return b
        }
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
