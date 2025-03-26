import Foundation
import Testing

@testable import Notion

@Test(.enabled(if: false, "Our token doesnt support user requests"))
func testGetUsers() async throws {
    guard let token = await Secrets.shared.get("NOTION_INTEGRATION_TOKEN") else {
        Issue.record("Missing NOTION_INTEGRATION_TOKEN environment variable")
        return
    }

    // Create a Notion client
    let notion = Notion(token: token)

    do {
        // Call the getUsers method
        let users = try await notion.getUsers()

        // Verify we received some users
        #expect(!users.isEmpty, "Expected to get at least one user")

        // Verify user data structure
        for user in users {
            #expect(user.object == "user", "Expected object type to be 'user'")
            #expect(!user.id.isEmpty, "Expected user to have a non-empty ID")

            // Check type-specific data
            switch user.type {
            case .person:
                #expect(user.person != nil, "Expected person data for user type 'person'")
                #expect(user.bot == nil, "Expected no bot data for user type 'person'")
                if let person = user.person {
                    #expect(!person.email.isEmpty, "Expected non-empty email for person")
                }

            case .bot:
                #expect(user.bot != nil, "Expected bot data for user type 'bot'")
                #expect(user.person == nil, "Expected no person data for user type 'bot'")
            }
        }
    } catch let error as NotionAPIError {
        if error.response.code == "restricted_resource" {
            print("Note: This test requires a Notion integration token with user capabilities")
            print("Error details: \(error.localizedDescription)")
            Issue.record("Insufficient permissions for accessing users endpoint")
        } else {
            throw error
        }
    }
}

@Test func testNotionAPIError() {
    // Test JSON for a Notion API error
    let errorJSON = """
        {"object":"error","status":403,"code":"restricted_resource","message":"Insufficient permissions for this endpoint.","request_id":"c4e35d81-6853-4d36-b061-939f24e4f9c8"}
        """.data(using: .utf8)!

    let decoder = JSONDecoder()
    let errorResponse = try! decoder.decode(NotionAPIError.Response.self, from: errorJSON)
    let error = NotionAPIError(response: errorResponse)

    #expect(error.response.status == 403)
    #expect(error.response.code == "restricted_resource")
    #expect(error.response.message == "Insufficient permissions for this endpoint.")
    #expect(error.response.requestID == "c4e35d81-6853-4d36-b061-939f24e4f9c8")
}

@Test func testGetPage() async throws {
    guard let token = await Secrets.shared.get("NOTION_INTEGRATION_TOKEN") else {
        Issue.record("Missing NOTION_INTEGRATION_TOKEN environment variable")
        return
    }

    let pageId = "222d1185-d9d4-400d-9f8d-0033be231409"

    // Create a Notion client
    let notion = Notion(token: token)

    do {
        // Call the getPage method
        let page = try await notion.getPage(id: pageId)

        // Verify basic page properties
        #expect(page.object == "page", "Expected object type to be 'page'")
        #expect(page.id == pageId, "Expected page ID to match requested ID")
        #expect(!page.url.absoluteString.isEmpty, "Expected page to have a URL")

        // Validate that we can access some properties
        if let titleProperty = page.properties.first(where: { $0.value.type == .title })?.value,
            let titleText = titleProperty.title?.first?.plainText
        {
            print("Page title: \(titleText)")
        }

    } catch let error as NotionAPIError {
        if error.response.code == "object_not_found" {
            Issue.record(
                "Page not found. Ensure the NOTION_TEST_PAGE_ID is correct and the integration has access to it."
            )
        } else {
            throw error
        }
    }
}

@Test func testGetPageContents() async throws {
    guard let token = await Secrets.shared.get("NOTION_INTEGRATION_TOKEN") else {
        Issue.record("Missing NOTION_INTEGRATION_TOKEN environment variable")
        return
    }

    let pageId = "1ad4dcaa-fc44-8140-bbaf-cd8d3f957c1b"

    // Create a Notion client
    let notion = Notion(token: token)

    do {
        // Use the new BlockChildrenSequence
        var blockCount = 0
        for try await block in notion.blockChildren(id: pageId) {
            #expect(block.object == "block", "Expected object type to be 'block'")
            #expect(!block.id.isEmpty, "Expected block to have a non-empty ID")
            blockCount += 1
        }
        print("Retrieved \(blockCount) blocks from page \(pageId)")
    } catch {
        print(error)
    }
}

@Test func testGetBlockChildren() async throws {
    guard let token = await Secrets.shared.get("NOTION_INTEGRATION_TOKEN") else {
        Issue.record("Missing NOTION_INTEGRATION_TOKEN environment variable")
        return
    }

    let pageId = "222d1185-d9d4-400d-9f8d-0033be231409"

    // Create a Notion client
    let notion = Notion(token: token)

    do {
        // Use the new BlockChildrenSequence
        var blocks: [Block] = []
        for try await block in notion.blockChildren(id: pageId) {
            blocks.append(block)
        }

        // Verify we received some blocks
        #expect(!blocks.isEmpty, "Expected to get at least one block")

        // Verify block data structure
        for block in blocks {
            #expect(block.object == "block", "Expected object type to be 'block'")
            #expect(!block.id.isEmpty, "Expected block to have a non-empty ID")
        }

        // Print some debug info about the blocks (optional)
        print("Retrieved \(blocks.count) blocks from page \(pageId)")

    } catch let error as NotionAPIError {
        if error.response.code == "object_not_found" {
            Issue.record(
                "Page not found. Ensure the pageId is correct and the integration has access to it."
            )
        } else {
            throw error
        }
    }
}

@Test func testBlockIO() throws {
    let json = """
    {
      "has_children" : true,
      "type" : "child_page",
      "archived" : false,
      "id" : "f9aa6fef-3bd2-4fc8-ad48-a764b8190b69",
      "created_by" : {
        "object" : "user",
        "id" : "d3d159f1-29b5-4a6a-ad08-fb46535ba381"
      },
      "last_edited_time" : "2024-07-10T16:42:00.000Z",
      "object" : "block",
      "last_edited_by" : {
        "object" : "user",
        "id" : "0aa39b50-3d96-4c27-bc65-a99645a2411c"
      },
      "parent" : {
        "page_id" : "222d1185-d9d4-400d-9f8d-0033be231409",
        "type" : "page_id"
      },
      "in_trash" : false,
      "child_page" : {
        "title" : "April 2024"
      },
      "created_time" : "2024-04-26T13:00:00.000Z"
    }
    """.data(using: .utf8)!
    let decoder = JSONDecoder()
    let block: Block = try decoder.decode(Block.self, from: json)
    print(block.json.rawString(options: .prettyPrinted)!)
}