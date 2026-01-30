import Foundation
import MetaCodable
import Testing

@Suite("Dynamic Codable Tests")
struct DynamicCodableTests {
    @Test("Decodes from JSON successfully (DynamicCodableTests #44)")
    func pageWithExtPost() throws {
        let page = try JSONDecoder().decode(
            PageWithExtPosts.self, from: dataPageWithExtPosts
        )
        for (index, item) in page.items.enumerated() {
            switch index {
            case 0:
                #expect(item is TextPost)
            case 1, 2:
                #expect(item is PicturePost)
            case 3:
                #expect(item is AudioPost)
            case 4:
                #expect(item is VideoPost)
            case 5:
                #expect(item is Nested.ValidPost)
            default:
                Issue.record("Invalid post count")
            }
        }
    }

    @Test("Decodes from JSON successfully (DynamicCodableTests #45)")
    func pageWithIntPost() throws {
        let page = try JSONDecoder().decode(
            PageWithIntPosts.self, from: dataPageWithIntPosts
        )
        for (index, item) in page.items.enumerated() {
            switch index {
            case 0:
                #expect(item is TextPost)
            case 1, 2:
                #expect(item is PicturePost)
            case 3:
                #expect(item is AudioPost)
            case 4:
                #expect(item is VideoPost)
            case 5:
                #expect(item is Nested.ValidPost)
            default:
                Issue.record("Invalid post count")
            }
        }
    }

    @Test("Decodes from JSON successfully (DynamicCodableTests #46)")
    func pageWithAdjPost() throws {
        let page = try JSONDecoder().decode(
            PageWithAdjPosts.self, from: dataPageWithAdjPosts
        )
        for (index, item) in page.items.enumerated() {
            switch index {
            case 0:
                #expect(item is TextPost)
            case 1, 2:
                #expect(item is PicturePost)
            case 3:
                #expect(item is AudioPost)
            case 4:
                #expect(item is VideoPost)
            case 5:
                #expect(item is Nested.ValidPost)
            default:
                Issue.record("Invalid post count")
            }
        }
    }

    @Test("Decodes from JSON successfully (DynamicCodableTests #47)")
    func response() throws {
        let rResponse = try JSONDecoder().decode(
            Response.self, from: registrationResponseAttributesData
        )
        #expect(rResponse.attributes is RegistrationAttributes)
        let vResponse = try JSONDecoder().decode(
            Response.self, from: verificationResponseAttributesData
        )
        #expect(vResponse.attributes is VerificationAttributes)
    }
}
