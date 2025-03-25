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

            // Check that the parent refers to our page
            #expect(block.parent.type == .pageId, "Expected parent type to be page_id")
            if block.parent.type == .pageId {
                #expect(block.parent.pageId == pageId, "Expected parent page ID to match our page ID")
            }

            // Verify metadata fields
            #expect(block.createdTime <= Date(), "Created time should be in the past")
            #expect(block.lastEditedTime <= Date(), "Last edited time should be in the past")
            #expect(!block.createdBy.id.isEmpty, "Expected creator to have an ID")
            #expect(!block.lastEditedBy.id.isEmpty, "Expected editor to have an ID")

            // Check type-specific data
            switch block.content {
            case .paragraph(let content):
                #expect(!content.richText.isEmpty, "Expected rich text content in paragraph")

            case .heading1(let content):
                #expect(!content.richText.isEmpty, "Expected rich text content in heading")

            case .heading2(let content):
                #expect(!content.richText.isEmpty, "Expected rich text content in heading")

            case .heading3(let content):
                #expect(!content.richText.isEmpty, "Expected rich text content in heading")

            case .bulletedListItem(let content):
                #expect(!content.richText.isEmpty, "Expected rich text content in list item")

            case .numberedListItem(let content):
                #expect(!content.richText.isEmpty, "Expected rich text content in numbered list item")

            case .image(let content):
                #expect(!content.type.isEmpty, "Expected file block to have a type")
                if content.type == "external" {
                    #expect(content.external != nil, "Expected external file data")
                } else {
                    #expect(content.file != nil, "Expected file data")
                }

            // Add more cases as needed for other block types
            default:
                // For brevity, we won't check all block types in this test
                print("Found block of type: \(block.type)")
            }
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
