import Foundation

public struct Notion: Sendable {
    /// The integration token used to authenticate with the Notion API.
    private static let baseURL = URL(string: "https://api.notion.com/v1/")!
    private static let apiVersion = "2022-06-28"

    private let token: String

    public init(token: String) {
        self.token = token
    }

    /// Internal routine to create a URL request with the proper headers.
    private func getRequest(for path: String, queryItems: [String: String]? = nil) async throws
        -> URLRequest
    {
        var components = URLComponents(
            url: Notion.baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: true)!

        if let queryItems = queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems.map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        guard let url = components.url else {
            let errorResponse = NotionAPIError.Response(
                object: "error",
                status: 400,
                code: "invalid_url",
                message: "Invalid URL components",
                requestID: nil
            )
            throw NotionAPIError(response: errorResponse)
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Notion.apiVersion, forHTTPHeaderField: "Notion-Version")
        return request
    }

    /// Processes API response data and checks for error responses
    private func processAPIResponse<T: Decodable>(data: Data) throws -> T {
        // Check if the response is an error
        try throwIfError(data: data)

        // If not an error, decode as the expected type
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func throwIfError(data: Data) throws {
        if let errorResponse = try? JSONDecoder().decode(NotionAPIError.Response.self, from: data),
            errorResponse.object == "error"
        {
            throw NotionAPIError(response: errorResponse)
        }
    }

    public func getUsers() async throws -> [User] {
        let request = try await getRequest(for: "users")
        let (data, _) = try await URLSession.shared.data(for: request)

        let listResponse: ListResponse<User> = try processAPIResponse(data: data)
        return listResponse.results
    }

    public func getPage(id: String) async throws -> Page {
        let request = try await getRequest(for: "pages/\(id)")
        let (data, _) = try await URLSession.shared.data(for: request)
        return try processAPIResponse(data: data)
    }

    public func createPage(parentId: String, title: String) async throws -> Page {
        let json: JSON = [
            "parent": ["type": "page_id", "page_id": parentId],
            "properties": ["title": [["text": ["content": title]]]],
        ]
        // json["parent"]["type"].string = "page_id"
        // json["parent"]["page_id"].string = parentId
        // json["properties"]["title"].arrayObject = [["text": ["content": title]]]

        let encoder = JSONEncoder()
        let data = try encoder.encode(json)

        var request = try await getRequest(for: "pages")
        request.httpMethod = "POST"
        request.httpBody = data

        let (response, _) = try await URLSession.shared.data(for: request)
        return try processAPIResponse(data: response)
    }

    internal func getBlockChildren(id: String, startCursor: String? = nil, pageSize: Int? = nil)
        async throws -> BlockChildrenResponse
    {
        var queryItems: [String: String] = [:]
        if let startCursor = startCursor {
            queryItems["start_cursor"] = startCursor
        }
        if let pageSize = pageSize {
            queryItems["page_size"] = "\(pageSize)"
        }

        let request = try await getRequest(
            for: "blocks/\(id)/children", queryItems: queryItems.isEmpty ? nil : queryItems)
        let (data, _) = try await URLSession.shared.data(for: request)

        let listResponse: ListResponse<Block> = try processAPIResponse(data: data)
        return BlockChildrenResponse(
            object: listResponse.object, results: listResponse.results,
            nextCursor: listResponse.nextCursor, hasMore: listResponse.hasMore)
    }

    /// Returns an AsyncSequence that lazily iterates through all children blocks
    public func blockChildren(id: String, pageSize: Int? = nil) -> BlockChildrenSequence {
        BlockChildrenSequence(notion: self, blockID: id, pageSize: pageSize)
    }

    public func deleteBlock(id: String) async throws {
        var request = try await getRequest(for: "blocks/\(id)")
        request.httpMethod = "DELETE"
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // Check for error responses from the API
        try throwIfError(data: data)
    }

    @discardableResult
    public func appendBlockChildren(id: String, blocks: [Block]) async throws -> ListResponse<Block>
    {
        let json: JSON = ["children": blocks.map { $0.json }]
        let encoder = JSONEncoder()
        let data = try encoder.encode(json)

        var request = try await getRequest(for: "blocks/\(id)/children")
        request.httpMethod = "PATCH"
        request.httpBody = data

        let (response, _) = try await URLSession.shared.data(for: request)

        return try processAPIResponse(data: response)
    }
    
    /// Query a Notion database with optional filters
    /// - Parameters:
    ///   - id: The database ID
    ///   - filter: Optional filter JSON object (see Notion API documentation for filter format)
    /// - Returns: A list response containing matching pages
    public func queryDatabase(id: String, filter: JSON? = nil) async throws -> ListResponse<Page> {
        var json: JSON = [:]
        if let filter = filter {
            json = json.merging(["filter": filter])
        }
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(json)
        
        var request = try await getRequest(for: "databases/\(id)/query")
        request.httpMethod = "POST"
        request.httpBody = data
        
        let (response, _) = try await URLSession.shared.data(for: request)
        
        return try processAPIResponse(data: response)
    }
    
    /// Create a new page in a database
    /// - Parameters:
    ///   - databaseId: The database ID
    ///   - properties: The properties to set on the new page (JSON object matching database schema)
    /// - Returns: The created page
    public func createDatabasePage(databaseId: String, properties: JSON) async throws -> Page {
        let json: JSON = [
            "parent": ["type": "database_id", "database_id": databaseId],
            "properties": properties
        ]
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(json)
        
        var request = try await getRequest(for: "pages")
        request.httpMethod = "POST"
        request.httpBody = data
        
        let (response, _) = try await URLSession.shared.data(for: request)
        return try processAPIResponse(data: response)
    }
}

/// Base protocol for all Notion objects
public protocol NotionObject: Sendable, Codable {
    var object: String { get }
}
