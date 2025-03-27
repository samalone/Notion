import Foundation
import Testing

@testable import Notion

@Test func testRichText() throws {
    let text = RichText("Hello, world!")

    print(text.prettyPrinted)
    #expect(text.json["type"].stringValue == "text")
    #expect(text.json["text"]["content"].stringValue == "Hello, world!")
    
    let italicText = try text.italic()
    print(italicText.prettyPrinted)
    #expect(italicText.json["annotations"]["italic"].boolValue)
    
    let boldText = try text.bold()
    #expect(boldText.json["annotations"]["bold"].boolValue)
    
    let redText = try text.color(.red)
    #expect(redText.json["annotations"]["color"].stringValue == "red")
}