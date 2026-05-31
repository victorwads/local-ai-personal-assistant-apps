import XCTest
@testable import AIAssistantHub

final class AIAssistantHubTests: XCTestCase {
    func testChatIdGeneratorNormalizesTitle() {
        let generator = ChatIdGenerator()
        XCTAssertEqual(generator.makeIdentifier(from: "  João   Silva  "), "joao-silva")
    }
}
