import Foundation

/// Represents a Notion user (person or bot)
public struct User: NotionObject, Sendable, Codable {
    public let object: String
    public let id: String
    public let name: String?
    public let avatarURL: URL?
    public let type: UserType
    
    // Type-specific data
    public let person: PersonData?
    public let bot: BotData?
    
    private enum CodingKeys: String, CodingKey {
        case object, id, name, type, person, bot
        case avatarURL = "avatar_url"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        object = try container.decode(String.self, forKey: .object)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        type = try container.decode(UserType.self, forKey: .type)
        
        if let urlString = try container.decodeIfPresent(String.self, forKey: .avatarURL) {
            avatarURL = URL(string: urlString)
        } else {
            avatarURL = nil
        }
        
        // Handle type-specific data
        switch type {
        case .person:
            person = try container.decodeIfPresent(PersonData.self, forKey: .person)
            bot = nil
        case .bot:
            bot = try container.decodeIfPresent(BotData.self, forKey: .bot)
            person = nil
        }
    }
}

/// The type of a Notion user
public enum UserType: String, Sendable, Codable {
    case person
    case bot
}

/// Data specific to person-type users
public struct PersonData: Sendable, Codable {
    public let email: String
}

/// Data specific to bot-type users
public struct BotData: Sendable, Codable {
    // Empty for now but conforms to the API structure
}
