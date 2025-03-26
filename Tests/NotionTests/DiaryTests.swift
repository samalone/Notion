import Foundation
import Testing

@testable import Notion

extension Notion {
    func findChildPageWithTitle(id: String, title: String) async throws -> String? {
        for try await block in blockChildren(id: id) {
            if case let .childPage(child) = block.content {
                if child.title == title {
                    return block.id
                }
            }
        }
        let page = try await createPage(parentId: id, title: title)
        return page.id
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

    let monthPage = try await notion.findChildPageWithTitle(id: diaryPageId, title: pageTitle)

    #expect(monthPage != nil, "Current month page not found")
}

extension DateFormatter {
    func monthYear(from date: Date) -> String {
        dateFormat = "MMMM yyyy"
        return string(from: date)
    }
}
