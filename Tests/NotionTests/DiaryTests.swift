import Foundation
import Testing

@testable import Notion

extension Notion {
    func findChildPageWithTitle(id: String, title: String) async throws -> String {
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

    func getCurrentMonthPageId() async throws -> String {

        // https://www.notion.so/Test-diary-1c24dcaafc448001b7e2ecac933e791e?pvs=4
        let diaryPageId = "1c24dcaafc448001b7e2ecac933e791e"

        // Get the current month in "September 2021" format
        let pageTitle = DateFormatter().monthYear(from: Date())

        return try await findChildPageWithTitle(id: diaryPageId, title: pageTitle)
    }

    func addTodayHeader(monthPageId: String) async throws {
        // Construct a day header of the form "Monday, April 22, 2024"
        let now = Date()
        let longDateStyle = DateFormatter()
        longDateStyle.dateStyle = .full
        longDateStyle.timeStyle = .none
        let longDate = longDateStyle.string(from: now)

        // Search for the last level 1 header with the day header text
        var lastHeading1: Block? = nil
        for try await block in blockChildren(id: monthPageId) {
            if block.object == "block",
                block.type == "heading_1"
            {
                lastHeading1 = block
            }
        }

        if lastHeading1?.content["rich_text", 0, "plain_text"].stringValue == longDate {
            return
        }

        try await appendBlockChildren(id: monthPageId, blocks: [.heading1(longDate)])
    }

    func startDiaryEntry() async throws {

        let monthPage = try await getCurrentMonthPageId()

        try await addTodayHeader(monthPageId: monthPage)

        // Format the current time as "12:34 PM"
        let timeFormat = DateFormatter()
        timeFormat.dateStyle = .none
        timeFormat.timeStyle = .short
        let time = timeFormat.string(from: Date())

        try await appendBlockChildren(id: monthPage, blocks: [.heading2(time)])
    }

    func endDiaryEntry() async throws {
        let monthPageId = try await getCurrentMonthPageId()

        try await deleteEmptyTrailingBlocks(pageId: monthPageId)

        try await addTodayHeader(monthPageId: monthPageId)

        // Construct a time header of the form "12:34 PM"
        let timeFormat = DateFormatter()
        timeFormat.dateStyle = .none
        timeFormat.timeStyle = .short
        let time = timeFormat.string(from: Date())

        // Find the last level 1 and 2 headers
        var startTimeHeader: Block? = nil
        var startDateHeader: Block? = nil
        for try await block in blockChildren(id: monthPageId) {
            if block.type == "heading_2" {
                startTimeHeader = block
            } else if block.type == "heading_1" {
                startDateHeader = block
            }
        }

        // If there is no start time header, then we can't end the diary entry.
        guard let startTimeHeader = startTimeHeader,
            let startDateHeader = startDateHeader
        else {
            return
        }

        // Parse the start time header to get the start time
        let fullFormat = DateFormatter()
        fullFormat.dateStyle = .full
        fullFormat.timeStyle = .short
        guard
            let startTime = fullFormat.date(
                from: startDateHeader.content["rich_text", 0, "plain_text"].stringValue + " at "
                    + startTimeHeader.content["rich_text", 0, "plain_text"].stringValue)
        else {
            return
        }

        // Insert a new paragraph block with the end time and duration of the diary entry.
        // The text is in the format "ended at 1:23 PM (duration 1:23)".
        // The paragraph should be in gray text and italicized.
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        let durationMinutes = Int(duration / 60)
        let durationHours = durationMinutes / 60
        let durationMinutesPart = durationMinutes % 60
        let durationText =
            "\(durationHours):\(String(durationMinutesPart).padding(toLength: 2, withPad: "0", startingAt: 0))"
        let endText = "Ended at \(time) (duration \(durationText))"

        try await appendBlockChildren(
            id: monthPageId, blocks: [.paragraph(RichText(endText).italic().color(.gray))])
    }
}

func getNotion() async -> Notion {
    guard let token = await Secrets.shared.get("NOTION_INTEGRATION_TOKEN") else {
        fatalError("Missing NOTION_INTEGRATION_TOKEN environment variable")
    }

    return Notion(token: token)
}

@Test func testNotionDiary() async throws {
    let notion = await getNotion()

    try await notion.startDiaryEntry()
    try await notion.endDiaryEntry()

    let monthPage = try await notion.getCurrentMonthPageId()

    try await notion.addTodayHeader(monthPageId: monthPage)

    let table = Block.table(
        rows: [
            ["Column 1", "Column 2", "Column 3"],
            ["Row 1, Column 1", "Row 1, Column 2", "Row 1, Column 3"],
            ["Row 2, Column 1", "Row 2, Column 2", "Row 2, Column 3"],
        ], hasColumnHeader: true)

    print(table.json.rawString(options: .prettyPrinted) ?? "")

    try await notion.appendBlockChildren(id: monthPage, blocks: [.heading1("Results"), table])
}

extension DateFormatter {
    func monthYear(from date: Date) -> String {
        dateFormat = "MMMM yyyy"
        return string(from: date)
    }
}
