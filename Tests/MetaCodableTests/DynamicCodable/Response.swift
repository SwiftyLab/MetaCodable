import MetaCodable

@Codable
@CodedAs<String?>
@CodedAt("operation")
protocol ResponseAttributes {
    var id: String { get }
}

@Codable
struct Response {
    @CodedIn("data")
    let id: String
    @CodedIn("data")
    let type: String
    @CodedIn("data")
    @CodedBy(ResponseAttributesCoder())
    let attributes: ResponseAttributes
}

@Codable
struct RegistrationAttributes: ResponseAttributes, DynamicCodable {
    static var identifier: DynamicCodableIdentifier<String?> {
        .one("REGISTRATION")
    }

    let id: String
    @CodedAt("status-code")
    let statusCode: String
}

@Codable
struct VerificationAttributes: ResponseAttributes, DynamicCodable {
    static var identifier: DynamicCodableIdentifier<String?> { nil }

    let id: String
    let expiresIn: UInt
    @CodedAt("xxx-token")
    let xxxToken: String
    @CodedAt("yyy-token")
    let yyyToken: String
}

let registrationResponseAttributesData = """
    {
        "data": {
            "id": "some UUID",
            "type": "Foo.Bar",
            "attributes": {
                "id": "another UUID",
                "mac": "message authentication code",
                "challenge": "some challenge",
                "operation": "REGISTRATION",
                "status-code": "200"
            }
        }
    }
    """.data(using: .utf8)!

let verificationResponseAttributesData = """
    {
        "data": {
            "id": "some UUID",
            "type": "Foo.Bar",
            "attributes": {
                "id": "another UUID",
                "expiresIn": 3600,
                "xxx-token": "xxxxxx",
                "yyy-token": "yyyyyyyyy"
            }
        }
    }
    """.data(using: .utf8)!
