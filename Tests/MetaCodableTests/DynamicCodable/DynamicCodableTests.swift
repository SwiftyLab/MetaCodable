import XCTest

final class DynamicCodableTests: XCTestCase {

    func testPageWithExtPost() throws {
        let page = try JSONDecoder().decode(
            PageWithExtPosts.self, from: dataPageWithExtPosts
        )
        for (index, item) in page.items.enumerated() {
            switch index {
            case 0:
                XCTAssertTrue(item.data is TextPost)
            case 1, 2:
                XCTAssertTrue(item.data is PicturePost)
            case 3:
                XCTAssertTrue(item.data is AudioPost)
            case 4:
                XCTAssertTrue(item.data is VideoPost)
            case 5:
                XCTAssertTrue(item.data is Nested.ValidPost)
            default:
                XCTFail("Invalid post count")
            }
        }
    }

    func testPageWithIntPost() throws {
        let page = try JSONDecoder().decode(
            PageWithIntPosts.self, from: dataPageWithIntPosts
        )
        for (index, item) in page.items.enumerated() {
            switch index {
            case 0:
                XCTAssertTrue(item.data is TextPost)
            case 1, 2:
                XCTAssertTrue(item.data is PicturePost)
            case 3:
                XCTAssertTrue(item.data is AudioPost)
            case 4:
                XCTAssertTrue(item.data is VideoPost)
            case 5:
                XCTAssertTrue(item.data is Nested.ValidPost)
            default:
                XCTFail("Invalid post count")
            }
        }
    }

    func testPageWithAdjPost() throws {
        let page = try JSONDecoder().decode(
            PageWithAdjPosts.self, from: dataPageWithAdjPosts
        )
        for (index, item) in page.items.enumerated() {
            switch index {
            case 0:
                XCTAssertTrue(item.data is TextPost)
            case 1, 2:
                XCTAssertTrue(item.data is PicturePost)
            case 3:
                XCTAssertTrue(item.data is AudioPost)
            case 4:
                XCTAssertTrue(item.data is VideoPost)
            case 5:
                XCTAssertTrue(item.data is Nested.ValidPost)
            default:
                XCTFail("Invalid post count")
            }
        }
    }
}
