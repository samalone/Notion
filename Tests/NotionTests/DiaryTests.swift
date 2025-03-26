import Foundation
import Testing

@testable import Notion

extension Notion {
    func findChildPageWithTitle(id: String, title: String) async throws -> String? {
        for try await block in blockChildren(id: id) {
            if block.childPageTitle == title {
                return block.id
            }
        }
        let page = try await createPage(parentId: id, title: title)
        return page.id
    }

    func deleteEmptyTrailingBlocks(pageId: String) async throws {
        var blockIdsToDelete: [String] = []
        for try await block in blockChildren(id: pageId) {
            if block.json["type"].stringValue == "paragraph"
                && block.json["paragraph"]["rich_text"].arrayValue.isEmpty
            {
                blockIdsToDelete.append(block.id)

            } else {
                blockIdsToDelete = []
            }
        }
        for blockId in blockIdsToDelete {
            try await deleteBlock(id: blockId)
        }
    }
}

@Test func getCurrentMonthPageId() async throws {
    guard let token = await Secrets.shared.get("NOTION_INTEGRATION_TOKEN") else {
        Issue.record("Missing NOTION_INTEGRATION_TOKEN environment variable")
        return
    }

    // https://www.notion.so/Test-diary-1c24dcaafc448001b7e2ecac933e791e?pvs=4
    let diaryPageId = "1c24dcaafc448001b7e2ecac933e791e"

    // Create a Notion client
    let notion = Notion(token: token)

    // Get the current month in "September 2021" format
    let pageTitle = DateFormatter().monthYear(from: Date())

    if let monthPage = try await notion.findChildPageWithTitle(id: diaryPageId, title: pageTitle) {
        try await notion.deleteEmptyTrailingBlocks(pageId: monthPage)
        try await notion.appendBlockChildren(id: monthPage, blocks: [
            Block.heading1("Heading 1"),
            Block.heading2("Heading 2"),
            Block.heading3("Heading 3"),
            Block.paragraph("Paragraph 1"),
            Block.paragraph(RichText("Paragraph 2").italic().color(.gray))
        ])
    }
}

extension DateFormatter {
    func monthYear(from date: Date) -> String {
        dateFormat = "MMMM yyyy"
        return string(from: date)
    }
}
