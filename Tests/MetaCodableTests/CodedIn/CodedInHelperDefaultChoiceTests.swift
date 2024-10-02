import HelperCoders
import MetaCodable
import Testing

@testable import PluginCore

struct CodedInHelperDefaultChoiceTests {
    struct WithNoPath {
        @Codable
        @MemberInit
        struct SomeCodable {
            @CodedBy(
                SequenceCoder(output: [String].self, configuration: .lossy)
            )
            @Default(ifMissing: ["some"], forErrors: ["another"])
            let value: [String]
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    @CodedBy(SequenceCoder(output: [String].self, configuration: .lossy))
                    @Default(ifMissing: ["some"], forErrors: ["another"])
                    let value: [String]
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        let value: [String]

                        init(value: [String] = ["some"]) {
                            self.value = value
                        }
                    }

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try? decoder.container(keyedBy: CodingKeys.self)
                            if let container = container {
                                do {
                                    self.value = try SequenceCoder(output: [String].self, configuration: .lossy).decodeIfPresent(from: container, forKey: CodingKeys.value) ?? ["some"]
                                } catch {
                                    self.value = ["another"]
                                }
                            } else {
                                self.value = ["another"]
                            }
                        }
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try SequenceCoder(output: [String].self, configuration: .lossy).encode(self.value, to: &container, atKey: CodingKeys.value)
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case value = "value"
                        }
                    }
                    """
            )
        }
    }

    struct WithNoPathOnOptionalType {
        @Codable
        @MemberInit
        struct SomeCodable {
            @CodedIn
            @Default(ifMissing: ["some"], forErrors: ["another"])
            @CodedBy(
                SequenceCoder(output: [String].self, configuration: .lossy)
            )
            let value: [String]?
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    @CodedIn
                    @Default(ifMissing: ["some"], forErrors: ["another"])
                    @CodedBy(SequenceCoder(output: [String].self, configuration: .lossy))
                    let value: [String]?
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        let value: [String]?

                        init(value: [String]? = ["some"]) {
                            self.value = value
                        }
                    }

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try? decoder.container(keyedBy: CodingKeys.self)
                            if let container = container {
                                do {
                                    self.value = try SequenceCoder(output: [String].self, configuration: .lossy).decodeIfPresent(from: container, forKey: CodingKeys.value) ?? ["some"]
                                } catch {
                                    self.value = ["another"]
                                }
                            } else {
                                self.value = ["another"]
                            }
                        }
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try SequenceCoder(output: [String].self, configuration: .lossy).encodeIfPresent(self.value, to: &container, atKey: CodingKeys.value)
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case value = "value"
                        }
                    }
                    """
            )
        }
    }

    struct WithSinglePath {
        @Codable
        @MemberInit
        struct SomeCodable {
            @Default(ifMissing: ["some"], forErrors: ["another"])
            @CodedBy(
                SequenceCoder(output: [String].self, configuration: .lossy)
            )
            @CodedIn("nested")
            let value: [String]
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    @Default(ifMissing: ["some"], forErrors: ["another"])
                    @CodedBy(SequenceCoder(output: [String].self, configuration: .lossy))
                    @CodedIn("nested")
                    let value: [String]
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        let value: [String]

                        init(value: [String] = ["some"]) {
                            self.value = value
                        }
                    }

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try? decoder.container(keyedBy: CodingKeys.self)
                            let nested_container: KeyedDecodingContainer<CodingKeys>?
                            let nested_containerMissing: Bool
                            if (try? container?.decodeNil(forKey: CodingKeys.nested)) == false {
                                nested_container = try? container?.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                                nested_containerMissing = false
                            } else {
                                nested_container = nil
                                nested_containerMissing = true
                            }
                            if let _ = container {
                                if let nested_container = nested_container {
                                    do {
                                        self.value = try SequenceCoder(output: [String].self, configuration: .lossy).decodeIfPresent(from: nested_container, forKey: CodingKeys.value) ?? ["some"]
                                    } catch {
                                        self.value = ["another"]
                                    }
                                } else if nested_containerMissing {
                                    self.value = ["some"]
                                } else {
                                    self.value = ["another"]
                                }
                            } else {
                                self.value = ["another"]
                            }
                        }
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            var nested_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                            try SequenceCoder(output: [String].self, configuration: .lossy).encode(self.value, to: &nested_container, atKey: CodingKeys.value)
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case value = "value"
                            case nested = "nested"
                        }
                    }
                    """
            )
        }
    }

    struct WithSinglePathOnOptionalType {
        @Codable
        @MemberInit
        struct SomeCodable {
            @Default(ifMissing: ["some"], forErrors: ["another"])
            @CodedIn("nested")
            @CodedBy(
                SequenceCoder(output: [String].self, configuration: .lossy)
            )
            let value: [String]?
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    @Default(ifMissing: ["some"], forErrors: ["another"])
                    @CodedIn("nested")
                    @CodedBy(SequenceCoder(output: [String].self, configuration: .lossy))
                    let value: [String]?
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        let value: [String]?

                        init(value: [String]? = ["some"]) {
                            self.value = value
                        }
                    }

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try? decoder.container(keyedBy: CodingKeys.self)
                            let nested_container: KeyedDecodingContainer<CodingKeys>?
                            let nested_containerMissing: Bool
                            if (try? container?.decodeNil(forKey: CodingKeys.nested)) == false {
                                nested_container = try? container?.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                                nested_containerMissing = false
                            } else {
                                nested_container = nil
                                nested_containerMissing = true
                            }
                            if let _ = container {
                                if let nested_container = nested_container {
                                    do {
                                        self.value = try SequenceCoder(output: [String].self, configuration: .lossy).decodeIfPresent(from: nested_container, forKey: CodingKeys.value) ?? ["some"]
                                    } catch {
                                        self.value = ["another"]
                                    }
                                } else if nested_containerMissing {
                                    self.value = ["some"]
                                } else {
                                    self.value = ["another"]
                                }
                            } else {
                                self.value = ["another"]
                            }
                        }
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            var nested_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                            try SequenceCoder(output: [String].self, configuration: .lossy).encodeIfPresent(self.value, to: &nested_container, atKey: CodingKeys.value)
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case value = "value"
                            case nested = "nested"
                        }
                    }
                    """
            )
        }
    }

    struct WithNestedPath {
        @Codable
        @MemberInit
        struct SomeCodable {
            @Default(ifMissing: ["some"], forErrors: ["another"])
            @CodedBy(
                SequenceCoder(output: [String].self, configuration: .lossy)
            )
            @CodedIn("deeply", "nested")
            let value: [String]
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    @Default(ifMissing: ["some"], forErrors: ["another"])
                    @CodedBy(SequenceCoder(output: [String].self, configuration: .lossy))
                    @CodedIn("deeply", "nested")
                    let value: [String]
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        let value: [String]

                        init(value: [String] = ["some"]) {
                            self.value = value
                        }
                    }

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try? decoder.container(keyedBy: CodingKeys.self)
                            let deeply_container: KeyedDecodingContainer<CodingKeys>?
                            let deeply_containerMissing: Bool
                            if (try? container?.decodeNil(forKey: CodingKeys.deeply)) == false {
                                deeply_container = try? container?.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                                deeply_containerMissing = false
                            } else {
                                deeply_container = nil
                                deeply_containerMissing = true
                            }
                            let nested_deeply_container: KeyedDecodingContainer<CodingKeys>?
                            let nested_deeply_containerMissing: Bool
                            if (try? deeply_container?.decodeNil(forKey: CodingKeys.nested)) == false {
                                nested_deeply_container = try? deeply_container?.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                                nested_deeply_containerMissing = false
                            } else {
                                nested_deeply_container = nil
                                nested_deeply_containerMissing = true
                            }
                            if let _ = container {
                                if let _ = deeply_container {
                                    if let nested_deeply_container = nested_deeply_container {
                                        do {
                                            self.value = try SequenceCoder(output: [String].self, configuration: .lossy).decodeIfPresent(from: nested_deeply_container, forKey: CodingKeys.value) ?? ["some"]
                                        } catch {
                                            self.value = ["another"]
                                        }
                                    } else if nested_deeply_containerMissing {
                                        self.value = ["some"]
                                    } else {
                                        self.value = ["another"]
                                    }
                                } else if deeply_containerMissing {
                                    self.value = ["some"]
                                } else {
                                    self.value = ["another"]
                                }
                            } else {
                                self.value = ["another"]
                            }
                        }
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            var deeply_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                            var nested_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                            try SequenceCoder(output: [String].self, configuration: .lossy).encode(self.value, to: &nested_deeply_container, atKey: CodingKeys.value)
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case value = "value"
                            case deeply = "deeply"
                            case nested = "nested"
                        }
                    }
                    """
            )
        }
    }

    struct WithNestedPathOnOptionalType {
        @Codable
        @MemberInit
        struct SomeCodable {
            @Default(ifMissing: ["some"], forErrors: ["another"])
            @CodedIn("deeply", "nested")
            @CodedBy(
                SequenceCoder(output: [String].self, configuration: .lossy)
            )
            let value: [String]?
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    @Default(ifMissing: ["some"], forErrors: ["another"])
                    @CodedIn("deeply", "nested")
                    @CodedBy(SequenceCoder(output: [String].self, configuration: .lossy))
                    let value: [String]?
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        let value: [String]?

                        init(value: [String]? = ["some"]) {
                            self.value = value
                        }
                    }

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try? decoder.container(keyedBy: CodingKeys.self)
                            let deeply_container: KeyedDecodingContainer<CodingKeys>?
                            let deeply_containerMissing: Bool
                            if (try? container?.decodeNil(forKey: CodingKeys.deeply)) == false {
                                deeply_container = try? container?.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                                deeply_containerMissing = false
                            } else {
                                deeply_container = nil
                                deeply_containerMissing = true
                            }
                            let nested_deeply_container: KeyedDecodingContainer<CodingKeys>?
                            let nested_deeply_containerMissing: Bool
                            if (try? deeply_container?.decodeNil(forKey: CodingKeys.nested)) == false {
                                nested_deeply_container = try? deeply_container?.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                                nested_deeply_containerMissing = false
                            } else {
                                nested_deeply_container = nil
                                nested_deeply_containerMissing = true
                            }
                            if let _ = container {
                                if let _ = deeply_container {
                                    if let nested_deeply_container = nested_deeply_container {
                                        do {
                                            self.value = try SequenceCoder(output: [String].self, configuration: .lossy).decodeIfPresent(from: nested_deeply_container, forKey: CodingKeys.value) ?? ["some"]
                                        } catch {
                                            self.value = ["another"]
                                        }
                                    } else if nested_deeply_containerMissing {
                                        self.value = ["some"]
                                    } else {
                                        self.value = ["another"]
                                    }
                                } else if deeply_containerMissing {
                                    self.value = ["some"]
                                } else {
                                    self.value = ["another"]
                                }
                            } else {
                                self.value = ["another"]
                            }
                        }
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            var deeply_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                            var nested_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                            try SequenceCoder(output: [String].self, configuration: .lossy).encodeIfPresent(self.value, to: &nested_deeply_container, atKey: CodingKeys.value)
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case value = "value"
                            case deeply = "deeply"
                            case nested = "nested"
                        }
                    }
                    """
            )
        }
    }

    struct WithNestedPathOnMultiOptionalTypes {
        @Codable
        @MemberInit
        struct SomeCodable {
            @Default(ifMissing: ["some"], forErrors: ["another"])
            @CodedIn("deeply", "nested")
            @CodedBy(
                SequenceCoder(output: [String].self, configuration: .lossy)
            )
            let value1: [String]?
            @Default(ifMissing: ["some"], forErrors: ["another"])
            @CodedIn("deeply", "nested")
            @CodedBy(
                SequenceCoder(output: [String].self, configuration: .lossy)
            )
            let value2: [String]?
            @Default(ifMissing: ["some"], forErrors: ["another"])
            @CodedIn("deeply", "nested")
            let value3: [String]?
            @CodedIn("deeply")
            @CodedBy(
                SequenceCoder(output: [String].self, configuration: .lossy)
            )
            let value4: [String]?
            @CodedIn("deeply")
            let value5: [String]?
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    @Default(ifMissing: ["some"], forErrors: ["another"])
                    @CodedIn("deeply", "nested")
                    @CodedBy(SequenceCoder(output: [String].self, configuration: .lossy))
                    let value1: [String]?
                    @Default(ifMissing: ["some"], forErrors: ["another"])
                    @CodedIn("deeply", "nested")
                    @CodedBy(SequenceCoder(output: [String].self, configuration: .lossy))
                    let value2: [String]?
                    @Default(ifMissing: ["some"], forErrors: ["another"])
                    @CodedIn("deeply", "nested")
                    let value3: [String]?
                    @CodedIn("deeply")
                    @CodedBy(SequenceCoder(output: [String].self, configuration: .lossy))
                    let value4: [String]?
                    @CodedIn("deeply")
                    let value5: [String]?
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        let value1: [String]?
                        let value2: [String]?
                        let value3: [String]?
                        let value4: [String]?
                        let value5: [String]?

                        init(value1: [String]? = ["some"], value2: [String]? = ["some"], value3: [String]? = ["some"], value4: [String]? = nil, value5: [String]? = nil) {
                            self.value1 = value1
                            self.value2 = value2
                            self.value3 = value3
                            self.value4 = value4
                            self.value5 = value5
                        }
                    }

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            let deeply_container = ((try? container.decodeNil(forKey: CodingKeys.deeply)) == false) ? try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply) : nil
                            let nested_deeply_container: KeyedDecodingContainer<CodingKeys>?
                            let nested_deeply_containerMissing: Bool
                            if (try? deeply_container?.decodeNil(forKey: CodingKeys.nested)) == false {
                                nested_deeply_container = try? deeply_container?.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                                nested_deeply_containerMissing = false
                            } else {
                                nested_deeply_container = nil
                                nested_deeply_containerMissing = true
                            }
                            if let deeply_container = deeply_container {
                                self.value4 = try SequenceCoder(output: [String].self, configuration: .lossy).decodeIfPresent(from: deeply_container, forKey: CodingKeys.value4)
                                self.value5 = try deeply_container.decodeIfPresent([String].self, forKey: CodingKeys.value5)
                                if let nested_deeply_container = nested_deeply_container {
                                    do {
                                        self.value1 = try SequenceCoder(output: [String].self, configuration: .lossy).decodeIfPresent(from: nested_deeply_container, forKey: CodingKeys.value1) ?? ["some"]
                                    } catch {
                                        self.value1 = ["another"]
                                    }
                                    do {
                                        self.value2 = try SequenceCoder(output: [String].self, configuration: .lossy).decodeIfPresent(from: nested_deeply_container, forKey: CodingKeys.value2) ?? ["some"]
                                    } catch {
                                        self.value2 = ["another"]
                                    }
                                    do {
                                        self.value3 = try nested_deeply_container.decodeIfPresent([String].self, forKey: CodingKeys.value3) ?? ["some"]
                                    } catch {
                                        self.value3 = ["another"]
                                    }
                                } else if nested_deeply_containerMissing {
                                    self.value1 = ["some"]
                                    self.value2 = ["some"]
                                    self.value3 = ["some"]
                                } else {
                                    self.value1 = ["another"]
                                    self.value2 = ["another"]
                                    self.value3 = ["another"]
                                }
                            } else {
                                self.value1 = ["some"]
                                self.value2 = ["some"]
                                self.value3 = ["some"]
                                self.value4 = nil
                                self.value5 = nil
                            }
                        }
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            var deeply_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                            var nested_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                            try SequenceCoder(output: [String].self, configuration: .lossy).encodeIfPresent(self.value1, to: &nested_deeply_container, atKey: CodingKeys.value1)
                            try SequenceCoder(output: [String].self, configuration: .lossy).encodeIfPresent(self.value2, to: &nested_deeply_container, atKey: CodingKeys.value2)
                            try nested_deeply_container.encodeIfPresent(self.value3, forKey: CodingKeys.value3)
                            try SequenceCoder(output: [String].self, configuration: .lossy).encodeIfPresent(self.value4, to: &deeply_container, atKey: CodingKeys.value4)
                            try deeply_container.encodeIfPresent(self.value5, forKey: CodingKeys.value5)
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case value1 = "value1"
                            case deeply = "deeply"
                            case nested = "nested"
                            case value2 = "value2"
                            case value3 = "value3"
                            case value4 = "value4"
                            case value5 = "value5"
                        }
                    }
                    """
            )
        }
    }

    struct WithNestedPathOnMixedTypes {
        @Codable
        @MemberInit
        struct SomeCodable {
            @Default(ifMissing: ["some"], forErrors: ["another"])
            @CodedBy(
                SequenceCoder(output: [String].self, configuration: .lossy)
            )
            @CodedIn("deeply", "nested", "level")
            let value1: [String]
            @Default(ifMissing: ["some"], forErrors: ["another"])
            @CodedBy(
                SequenceCoder(output: [String].self, configuration: .lossy)
            )
            @CodedIn("deeply", "nested", "level")
            let value2: [String]?
            @CodedIn("deeply", "nested")
            @CodedBy(
                SequenceCoder(output: [String].self, configuration: .lossy)
            )
            let value3: [String]?
            @CodedIn("deeply", "nested")
            let value4: [String]?
            @CodedIn("deeply")
            @CodedBy(
                SequenceCoder(output: [String].self, configuration: .lossy)
            )
            let value5: [String]
            @CodedIn("deeply")
            let value6: [String]
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    @Default(ifMissing: ["some"], forErrors: ["another"])
                    @CodedBy(SequenceCoder(output: [String].self, configuration: .lossy))
                    @CodedIn("deeply", "nested", "level")
                    let value1: [String]
                    @Default(ifMissing: ["some"], forErrors: ["another"])
                    @CodedBy(SequenceCoder(output: [String].self, configuration: .lossy))
                    @CodedIn("deeply", "nested", "level")
                    let value2: [String]?
                    @CodedIn("deeply", "nested")
                    @CodedBy(SequenceCoder(output: [String].self, configuration: .lossy))
                    let value3: [String]?
                    @CodedIn("deeply", "nested")
                    let value4: [String]?
                    @CodedIn("deeply")
                    @CodedBy(SequenceCoder(output: [String].self, configuration: .lossy))
                    let value5: [String]
                    @CodedIn("deeply")
                    let value6: [String]
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        let value1: [String]
                        let value2: [String]?
                        let value3: [String]?
                        let value4: [String]?
                        let value5: [String]
                        let value6: [String]

                        init(value1: [String] = ["some"], value2: [String]? = ["some"], value3: [String]? = nil, value4: [String]? = nil, value5: [String], value6: [String]) {
                            self.value1 = value1
                            self.value2 = value2
                            self.value3 = value3
                            self.value4 = value4
                            self.value5 = value5
                            self.value6 = value6
                        }
                    }

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            let deeply_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                            let nested_deeply_container = ((try? deeply_container.decodeNil(forKey: CodingKeys.nested)) == false) ? try deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested) : nil
                            let level_nested_deeply_container: KeyedDecodingContainer<CodingKeys>?
                            let level_nested_deeply_containerMissing: Bool
                            if (try? nested_deeply_container?.decodeNil(forKey: CodingKeys.level)) == false {
                                level_nested_deeply_container = try? nested_deeply_container?.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.level)
                                level_nested_deeply_containerMissing = false
                            } else {
                                level_nested_deeply_container = nil
                                level_nested_deeply_containerMissing = true
                            }
                            self.value5 = try SequenceCoder(output: [String].self, configuration: .lossy).decode(from: deeply_container, forKey: CodingKeys.value5)
                            self.value6 = try deeply_container.decode([String].self, forKey: CodingKeys.value6)
                            if let nested_deeply_container = nested_deeply_container {
                                self.value3 = try SequenceCoder(output: [String].self, configuration: .lossy).decodeIfPresent(from: nested_deeply_container, forKey: CodingKeys.value3)
                                self.value4 = try nested_deeply_container.decodeIfPresent([String].self, forKey: CodingKeys.value4)
                                if let level_nested_deeply_container = level_nested_deeply_container {
                                    do {
                                        self.value1 = try SequenceCoder(output: [String].self, configuration: .lossy).decodeIfPresent(from: level_nested_deeply_container, forKey: CodingKeys.value1) ?? ["some"]
                                    } catch {
                                        self.value1 = ["another"]
                                    }
                                    do {
                                        self.value2 = try SequenceCoder(output: [String].self, configuration: .lossy).decodeIfPresent(from: level_nested_deeply_container, forKey: CodingKeys.value2) ?? ["some"]
                                    } catch {
                                        self.value2 = ["another"]
                                    }
                                } else if level_nested_deeply_containerMissing {
                                    self.value1 = ["some"]
                                    self.value2 = ["some"]
                                } else {
                                    self.value1 = ["another"]
                                    self.value2 = ["another"]
                                }
                            } else {
                                self.value1 = ["some"]
                                self.value2 = ["some"]
                                self.value3 = nil
                                self.value4 = nil
                            }
                        }
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            var deeply_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                            var nested_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                            var level_nested_deeply_container = nested_deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.level)
                            try SequenceCoder(output: [String].self, configuration: .lossy).encode(self.value1, to: &level_nested_deeply_container, atKey: CodingKeys.value1)
                            try SequenceCoder(output: [String].self, configuration: .lossy).encodeIfPresent(self.value2, to: &level_nested_deeply_container, atKey: CodingKeys.value2)
                            try SequenceCoder(output: [String].self, configuration: .lossy).encodeIfPresent(self.value3, to: &nested_deeply_container, atKey: CodingKeys.value3)
                            try nested_deeply_container.encodeIfPresent(self.value4, forKey: CodingKeys.value4)
                            try SequenceCoder(output: [String].self, configuration: .lossy).encode(self.value5, to: &deeply_container, atKey: CodingKeys.value5)
                            try deeply_container.encode(self.value6, forKey: CodingKeys.value6)
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case value1 = "value1"
                            case deeply = "deeply"
                            case nested = "nested"
                            case level = "level"
                            case value2 = "value2"
                            case value3 = "value3"
                            case value4 = "value4"
                            case value5 = "value5"
                            case value6 = "value6"
                        }
                    }
                    """
            )
        }
    }

    struct ClassWithNestedPathOnMixedTypes {
        @Codable
        class SomeCodable {
            @Default(ifMissing: ["some"], forErrors: ["another"])
            @CodedBy(
                SequenceCoder(output: [String].self, configuration: .lossy)
            )
            @CodedIn("deeply", "nested", "level")
            let value1: [String]
            @Default(ifMissing: ["some"], forErrors: ["another"])
            @CodedBy(
                SequenceCoder(output: [String].self, configuration: .lossy)
            )
            @CodedIn("deeply", "nested", "level")
            let value2: [String]?
            @CodedIn("deeply", "nested")
            @CodedBy(
                SequenceCoder(output: [String].self, configuration: .lossy)
            )
            let value3: [String]?
            @CodedIn("deeply", "nested")
            let value4: [String]?
            @CodedIn("deeply")
            @CodedBy(
                SequenceCoder(output: [String].self, configuration: .lossy)
            )
            let value5: [String]
            @CodedIn("deeply")
            let value6: [String]
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                class SomeCodable {
                    @Default(ifMissing: ["some"], forErrors: ["another"])
                    @CodedBy(SequenceCoder(output: [String].self, configuration: .lossy))
                    @CodedIn("deeply", "nested", "level")
                    let value1: [String]
                    @Default(ifMissing: ["some"], forErrors: ["another"])
                    @CodedBy(SequenceCoder(output: [String].self, configuration: .lossy))
                    @CodedIn("deeply", "nested", "level")
                    let value2: [String]?
                    @CodedIn("deeply", "nested")
                    @CodedBy(SequenceCoder(output: [String].self, configuration: .lossy))
                    let value3: [String]?
                    @CodedIn("deeply", "nested")
                    let value4: [String]?
                    @CodedIn("deeply")
                    @CodedBy(SequenceCoder(output: [String].self, configuration: .lossy))
                    let value5: [String]
                    @CodedIn("deeply")
                    let value6: [String]
                }
                """,
                expandedSource:
                    """
                    class SomeCodable {
                        let value1: [String]
                        let value2: [String]?
                        let value3: [String]?
                        let value4: [String]?
                        let value5: [String]
                        let value6: [String]

                        required init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            let deeply_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                            let nested_deeply_container = ((try? deeply_container.decodeNil(forKey: CodingKeys.nested)) == false) ? try deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested) : nil
                            let level_nested_deeply_container: KeyedDecodingContainer<CodingKeys>?
                            let level_nested_deeply_containerMissing: Bool
                            if (try? nested_deeply_container?.decodeNil(forKey: CodingKeys.level)) == false {
                                level_nested_deeply_container = try? nested_deeply_container?.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.level)
                                level_nested_deeply_containerMissing = false
                            } else {
                                level_nested_deeply_container = nil
                                level_nested_deeply_containerMissing = true
                            }
                            self.value5 = try SequenceCoder(output: [String].self, configuration: .lossy).decode(from: deeply_container, forKey: CodingKeys.value5)
                            self.value6 = try deeply_container.decode([String].self, forKey: CodingKeys.value6)
                            if let nested_deeply_container = nested_deeply_container {
                                self.value3 = try SequenceCoder(output: [String].self, configuration: .lossy).decodeIfPresent(from: nested_deeply_container, forKey: CodingKeys.value3)
                                self.value4 = try nested_deeply_container.decodeIfPresent([String].self, forKey: CodingKeys.value4)
                                if let level_nested_deeply_container = level_nested_deeply_container {
                                    do {
                                        self.value1 = try SequenceCoder(output: [String].self, configuration: .lossy).decodeIfPresent(from: level_nested_deeply_container, forKey: CodingKeys.value1) ?? ["some"]
                                    } catch {
                                        self.value1 = ["another"]
                                    }
                                    do {
                                        self.value2 = try SequenceCoder(output: [String].self, configuration: .lossy).decodeIfPresent(from: level_nested_deeply_container, forKey: CodingKeys.value2) ?? ["some"]
                                    } catch {
                                        self.value2 = ["another"]
                                    }
                                } else if level_nested_deeply_containerMissing {
                                    self.value1 = ["some"]
                                    self.value2 = ["some"]
                                } else {
                                    self.value1 = ["another"]
                                    self.value2 = ["another"]
                                }
                            } else {
                                self.value1 = ["some"]
                                self.value2 = ["some"]
                                self.value3 = nil
                                self.value4 = nil
                            }
                        }

                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            var deeply_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                            var nested_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                            var level_nested_deeply_container = nested_deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.level)
                            try SequenceCoder(output: [String].self, configuration: .lossy).encode(self.value1, to: &level_nested_deeply_container, atKey: CodingKeys.value1)
                            try SequenceCoder(output: [String].self, configuration: .lossy).encodeIfPresent(self.value2, to: &level_nested_deeply_container, atKey: CodingKeys.value2)
                            try SequenceCoder(output: [String].self, configuration: .lossy).encodeIfPresent(self.value3, to: &nested_deeply_container, atKey: CodingKeys.value3)
                            try nested_deeply_container.encodeIfPresent(self.value4, forKey: CodingKeys.value4)
                            try SequenceCoder(output: [String].self, configuration: .lossy).encode(self.value5, to: &deeply_container, atKey: CodingKeys.value5)
                            try deeply_container.encode(self.value6, forKey: CodingKeys.value6)
                        }

                        enum CodingKeys: String, CodingKey {
                            case value1 = "value1"
                            case deeply = "deeply"
                            case nested = "nested"
                            case level = "level"
                            case value2 = "value2"
                            case value3 = "value3"
                            case value4 = "value4"
                            case value5 = "value5"
                            case value6 = "value6"
                        }
                    }

                    extension SomeCodable: Decodable {
                    }

                    extension SomeCodable: Encodable {
                    }
                    """
            )
        }
    }
}
