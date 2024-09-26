import Foundation
import MetaCodable
import Testing

struct DynamicCodableTests {
    @Test
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

    @Test
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

    @Test
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

    @Test
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
