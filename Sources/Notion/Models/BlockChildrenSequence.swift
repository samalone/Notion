//
//  BlockChildrenSequence.swift
//  Notion
//
//  Created by Stuart Malone on 3/25/25.
//



// Add new AsyncSequence to iterate over block children
public struct BlockChildrenSequence: AsyncSequence, Sendable {
    public typealias Element = Block

    private let notion: Notion
    private let blockID: String
    private let pageSize: Int?
    
    public init(notion: Notion, blockID: String, pageSize: Int? = nil) {
        self.notion = notion
        self.blockID = blockID
        self.pageSize = pageSize
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(notion: notion, blockID: blockID, pageSize: pageSize)
    }
    
    public struct Iterator: AsyncIteratorProtocol, Sendable {
        private let notion: Notion
        private let blockID: String
        private let pageSize: Int?
        private var currentBatch: [Block] = []
        private var nextCursor: String? = nil
        private var finished = false
        
        init(notion: Notion, blockID: String, pageSize: Int?) {
            self.notion = notion
            self.blockID = blockID
            self.pageSize = pageSize
        }
        
        public mutating func next() async throws -> Block? {
            while currentBatch.isEmpty && !finished {
                let response = try await notion.getBlockChildren(id: blockID, startCursor: nextCursor, pageSize: pageSize)
                currentBatch.append(contentsOf: response.results)
                nextCursor = response.nextCursor
                finished = !response.hasMore
            }
            return currentBatch.isEmpty ? nil : currentBatch.removeFirst()
        }
    }
}
