//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum AWSComprehend {}

extension AWSComprehend {
    struct InternalServerException: Error {}
    struct InvalidRequestException: Error {}
    struct TextSizeLimitExceededException: Error {}
}

public struct DetectSentimentInput: Swift.Equatable {
    /// This member is required.
    public var languageCode: ComprehendClientTypes.LanguageCode
    /// This member is required.
    public var text: Swift.String

    enum CodingKeys: Swift.String, Swift.CodingKey {
        case languageCode = "LanguageCode"
        case text = "Text"
    }
}

public struct DetectSentimentOutputResponse: Swift.Equatable {
    public var sentiment: ComprehendClientTypes.SentimentType?
    public var sentimentScore: ComprehendClientTypes.SentimentScore?

    enum CodingKeys: Swift.String, Swift.CodingKey {
        case sentiment = "Sentiment"
        case sentimentScore = "SentimentScore"
    }
}

public struct DetectEntitiesInput: Swift.Equatable {
    public var bytes: Data?
    public var documentReaderConfig: ComprehendClientTypes.DocumentReaderConfig?
    public var endpointArn: Swift.String?
    public var languageCode: ComprehendClientTypes.LanguageCode?
    public var text: Swift.String?

    enum CodingKeys: Swift.String, Swift.CodingKey {
        case bytes = "Bytes"
        case documentReaderConfig = "DocumentReaderConfig"
        case endpointArn = "EndpointArn"
        case languageCode = "LanguageCode"
        case text = "Text"
    }
}

public struct DetectEntitiesOutputResponse: Swift.Equatable {
    public var blocks: [ComprehendClientTypes.Block]?
    public var documentMetadata: ComprehendClientTypes.DocumentMetadata?
    public var documentType: [ComprehendClientTypes.DocumentTypeListItem]?
    public var entities: [ComprehendClientTypes.Entity]?
    public var errors: [ComprehendClientTypes.ErrorsListItem]?
    
    enum CodingKeys: Swift.String, Swift.CodingKey {
        case blocks = "Blocks"
        case documentMetadata = "DocumentMetadata"
        case documentType = "DocumentType"
        case entities = "Entities"
        case errors = "Errors"
    }
}


public struct DetectKeyPhrasesInput: Swift.Equatable {
    /// This member is required.
    public var languageCode: ComprehendClientTypes.LanguageCode
    /// This member is required.
    public var text: Swift.String

    enum CodingKeys: Swift.String, Swift.CodingKey {
        case languageCode = "LanguageCode"
        case text = "Text"
    }
}

public struct DetectKeyPhrasesOutputResponse: Swift.Equatable {
    public var keyPhrases: [ComprehendClientTypes.KeyPhrase]?

    enum CodingKeys: Swift.String, Swift.CodingKey {
        case keyPhrases = "KeyPhrases"
    }
}

public struct DetectSyntaxInput: Swift.Equatable {
    /// This member is required.
    public var languageCode: ComprehendClientTypes.SyntaxLanguageCode
    /// This member is required.
    public var text: Swift.String

    enum CodingKeys: Swift.String, Swift.CodingKey {
        case languageCode = "LanguageCode"
        case text = "Text"
    }
}

public struct DetectSyntaxOutputResponse: Swift.Equatable {
    public var syntaxTokens: [ComprehendClientTypes.SyntaxToken]?

    enum CodingKeys: Swift.String, Swift.CodingKey {
        case syntaxTokens = "SyntaxTokens"
    }
}

public struct DetectDominantLanguageInput: Swift.Equatable {
    /// This member is required.
    public var text: Swift.String

    enum CodingKeys: Swift.String, Swift.CodingKey {
        case text = "Text"
    }
}

public struct DetectDominantLanguageOutputResponse: Swift.Equatable {
    public var languages: [ComprehendClientTypes.DominantLanguage]?

    enum CodingKeys: Swift.String, Swift.CodingKey {
        case languages = "Languages"
    }
}

public enum ComprehendClientTypes {}

extension ComprehendClientTypes {
    public struct SentimentScore: Swift.Equatable {
        public var mixed: Swift.Float?
        public var negative: Swift.Float?
        public var neutral: Swift.Float?
        public var positive: Swift.Float?
    }
}

extension ComprehendClientTypes {
    public enum DocumentReadMode: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
        case forceDocumentReadAction
        case serviceDefault
        case sdkUnknown(Swift.String)

        public static var allCases: [DocumentReadMode] {
            return [
                .forceDocumentReadAction,
                .serviceDefault,
                .sdkUnknown("")
            ]
        }
        public init?(rawValue: Swift.String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        public var rawValue: Swift.String {
            switch self {
            case .forceDocumentReadAction: return "FORCE_DOCUMENT_READ_ACTION"
            case .serviceDefault: return "SERVICE_DEFAULT"
            case let .sdkUnknown(s): return s
            }
        }
        public init(from decoder: Swift.Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = DocumentReadMode(rawValue: rawValue) ?? DocumentReadMode.sdkUnknown(rawValue)
        }
    }
}

extension ComprehendClientTypes {
    public enum DocumentReadAction: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
        case textractAnalyzeDocument
        case textractDetectDocumentText
        case sdkUnknown(Swift.String)

        public static var allCases: [DocumentReadAction] {
            return [
                .textractAnalyzeDocument,
                .textractDetectDocumentText,
                .sdkUnknown("")
            ]
        }
        public init?(rawValue: Swift.String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        public var rawValue: Swift.String {
            switch self {
            case .textractAnalyzeDocument: return "TEXTRACT_ANALYZE_DOCUMENT"
            case .textractDetectDocumentText: return "TEXTRACT_DETECT_DOCUMENT_TEXT"
            case let .sdkUnknown(s): return s
            }
        }
        public init(from decoder: Swift.Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = DocumentReadAction(rawValue: rawValue) ?? DocumentReadAction.sdkUnknown(rawValue)
        }
    }
}

extension ComprehendClientTypes {
    public enum DocumentReadFeatureTypes: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
        case forms
        case tables
        case sdkUnknown(Swift.String)

        public static var allCases: [DocumentReadFeatureTypes] {
            return [
                .forms,
                .tables,
                .sdkUnknown("")
            ]
        }
        public init?(rawValue: Swift.String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        public var rawValue: Swift.String {
            switch self {
            case .forms: return "FORMS"
            case .tables: return "TABLES"
            case let .sdkUnknown(s): return s
            }
        }
        public init(from decoder: Swift.Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = DocumentReadFeatureTypes(rawValue: rawValue) ?? DocumentReadFeatureTypes.sdkUnknown(rawValue)
        }
    }
}


extension ComprehendClientTypes {
    public struct DocumentReaderConfig: Swift.Equatable {
        /// This member is required.
        public var documentReadAction: ComprehendClientTypes.DocumentReadAction
        public var documentReadMode: ComprehendClientTypes.DocumentReadMode?
        public var featureTypes: [ComprehendClientTypes.DocumentReadFeatureTypes]?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case documentReadAction = "DocumentReadAction"
            case documentReadMode = "DocumentReadMode"
            case featureTypes = "FeatureTypes"
        }
    }
}

extension ComprehendClientTypes {
    public enum DocumentType: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
        case image
        case msWord
        case nativePdf
        case plainText
        case scannedPdf
        case textractAnalyzeDocumentJson
        case textractDetectDocumentTextJson
        case sdkUnknown(Swift.String)

        public static var allCases: [DocumentType] {
            return [
                .image,
                .msWord,
                .nativePdf,
                .nativePdf,
                .plainText,
                .scannedPdf,
                .textractAnalyzeDocumentJson,
                .textractDetectDocumentTextJson,
                .sdkUnknown("")
            ]
        }
        public init?(rawValue: Swift.String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        public var rawValue: Swift.String {
            switch self {
            case .image: return "IMAGE"
            case .msWord: return "MS_WORD"
            case .nativePdf: return "NATIVE_PDF"
            case .plainText: return "PLAIN_TEXT"
            case .scannedPdf: return "SCANNED_PDF"
            case .textractAnalyzeDocumentJson: return "TEXTRACT_ANALYZE_DOCUMENT_JSON"
            case .textractDetectDocumentTextJson: return "TEXTRACT_DETECT_DOCUMENT_TEXT_JSON"
            case let .sdkUnknown(s): return s
            }
        }
        public init(from decoder: Swift.Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = DocumentType(rawValue: rawValue) ?? DocumentType.sdkUnknown(rawValue)
        }
    }
}

extension ComprehendClientTypes {
    /// Document type for each page in the document.
    public struct DocumentTypeListItem: Swift.Equatable {
        /// Page number.
        public var page: Swift.Int?
        /// Document type.
        public var type: ComprehendClientTypes.DocumentType?
    }
}

extension ComprehendClientTypes {
    public enum PageBasedErrorCode: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
        case internalServerError
        case pageCharactersExceeded
        case pageSizeExceeded
        case textractBadPage
        case textractProvisionedThroughputExceeded
        case sdkUnknown(Swift.String)

        public static var allCases: [PageBasedErrorCode] {
            return [
                .internalServerError,
                .pageCharactersExceeded,
                .pageSizeExceeded,
                .textractBadPage,
                .textractProvisionedThroughputExceeded,
                .sdkUnknown("")
            ]
        }
        public init?(rawValue: Swift.String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        public var rawValue: Swift.String {
            switch self {
            case .internalServerError: return "INTERNAL_SERVER_ERROR"
            case .pageCharactersExceeded: return "PAGE_CHARACTERS_EXCEEDED"
            case .pageSizeExceeded: return "PAGE_SIZE_EXCEEDED"
            case .textractBadPage: return "TEXTRACT_BAD_PAGE"
            case .textractProvisionedThroughputExceeded: return "TEXTRACT_PROVISIONED_THROUGHPUT_EXCEEDED"
            case let .sdkUnknown(s): return s
            }
        }
        public init(from decoder: Swift.Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = PageBasedErrorCode(rawValue: rawValue) ?? PageBasedErrorCode.sdkUnknown(rawValue)
        }
    }
}

extension ComprehendClientTypes {
    public struct ErrorsListItem: Swift.Equatable {
        public var errorCode: ComprehendClientTypes.PageBasedErrorCode?
        public var errorMessage: Swift.String?
        public var page: Swift.Int?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case errorCode = "ErrorCode"
            case errorMessage = "ErrorMessage"
            case page = "Page"
        }
    }
}

extension ComprehendClientTypes {
    public struct ChildBlock: Swift.Equatable {
        public var beginOffset: Swift.Int?
        public var childBlockId: Swift.String?
        public var endOffset: Swift.Int?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case beginOffset = "BeginOffset"
            case childBlockId = "ChildBlockId"
            case endOffset = "EndOffset"
        }
    }
}


extension ComprehendClientTypes {
    public struct BlockReference: Swift.Equatable {
        public var beginOffset: Swift.Int?
        public var blockId: Swift.String?
        public var childBlocks: [ComprehendClientTypes.ChildBlock]?
        public var endOffset: Swift.Int?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case beginOffset = "BeginOffset"
            case blockId = "BlockId"
            case childBlocks = "ChildBlocks"
            case endOffset = "EndOffset"
        }
    }
}

extension ComprehendClientTypes {
    /// Provides information about an entity.
    public struct Entity: Swift.Equatable {
        /// The zero-based offset from the beginning of the source text to the first character in the entity. This field is empty for non-text input.
        public var beginOffset: Swift.Int?
        /// A reference to each block for this entity. This field is empty for plain-text input.
        public var blockReferences: [ComprehendClientTypes.BlockReference]?
        /// The zero-based offset from the beginning of the source text to the last character in the entity. This field is empty for non-text input.
        public var endOffset: Swift.Int?
        /// The level of confidence that Amazon Comprehend has in the accuracy of the detection.
        public var score: Swift.Float?
        /// The text of the entity.
        public var text: Swift.String?
        /// The entity type. For entity detection using the built-in model, this field contains one of the standard entity types listed below. For custom entity detection, this field contains one of the entity types that you specified when you trained your custom model.
        public var type: ComprehendClientTypes.EntityType?

        public init(
            beginOffset: Swift.Int? = nil,
            blockReferences: [ComprehendClientTypes.BlockReference]? = nil,
            endOffset: Swift.Int? = nil,
            score: Swift.Float? = nil,
            text: Swift.String? = nil,
            type: ComprehendClientTypes.EntityType? = nil
        )
        {
            self.beginOffset = beginOffset
            self.blockReferences = blockReferences
            self.endOffset = endOffset
            self.score = score
            self.text = text
            self.type = type
        }
    }
}

extension ComprehendClientTypes {
    public struct ExtractedCharactersListItem: Swift.Equatable {
        public var count: Swift.Int?
        public var page: Swift.Int?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case count = "Count"
            case page = "Page"
        }
    }
}

extension ComprehendClientTypes {
    public struct DocumentMetadata: Swift.Equatable {
        public var extractedCharacters: [ComprehendClientTypes.ExtractedCharactersListItem]?
        public var pages: Swift.Int?
    }
}

extension ComprehendClientTypes {
    public struct Geometry: Swift.Equatable {
        public var boundingBox: ComprehendClientTypes.BoundingBox?
        public var polygon: [ComprehendClientTypes.Point]?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case boundingBox = "BoundingBox"
            case polygon = "Polygon"
        }
    }
}

extension ComprehendClientTypes {
    public struct BoundingBox: Swift.Equatable {
        public var height: Swift.Float?
        public var `left`: Swift.Float?
        public var top: Swift.Float?
        public var width: Swift.Float?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case height = "Height"
            case `left` = "Left"
            case top = "Top"
            case width = "Width"
        }
    }
}

extension ComprehendClientTypes {
    public struct Point: Swift.Equatable {
        public var x: Swift.Float?
        public var y: Swift.Float?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case x = "X"
            case y = "Y"
        }
    }
}

extension ComprehendClientTypes {
    public enum BlockType: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
        case line
        case word
        case sdkUnknown(Swift.String)

        public static var allCases: [BlockType] {
            return [
                .line,
                .word,
                .sdkUnknown("")
            ]
        }
        public init?(rawValue: Swift.String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        public var rawValue: Swift.String {
            switch self {
            case .line: return "LINE"
            case .word: return "WORD"
            case let .sdkUnknown(s): return s
            }
        }
        public init(from decoder: Swift.Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = BlockType(rawValue: rawValue) ?? BlockType.sdkUnknown(rawValue)
        }
    }
}

extension ComprehendClientTypes {
    /// Information about each word or line of text in the input document. For additional information, see [Block](https://docs.aws.amazon.com/textract/latest/dg/API_Block.html) in the Amazon Textract API reference.
    public struct Block: Swift.Equatable {
        /// The block represents a line of text or one word of text.
        ///
        /// * WORD - A word that's detected on a document page. A word is one or more ISO basic Latin script characters that aren't separated by spaces.
        ///
        /// * LINE - A string of tab-delimited, contiguous words that are detected on a document page
        public var blockType: ComprehendClientTypes.BlockType?
        /// Co-ordinates of the rectangle or polygon that contains the text.
        public var geometry: ComprehendClientTypes.Geometry?
        /// Unique identifier for the block.
        public var id: Swift.String?
        /// Page number where the block appears.
        public var page: Swift.Int?
        /// A list of child blocks of the current block. For example, a LINE object has child blocks for each WORD block that's part of the line of text.
        public var relationships: [ComprehendClientTypes.RelationshipsListItem]?
        /// The word or line of text extracted from the block.
        public var text: Swift.String?


    }

}

extension ComprehendClientTypes {
    public struct RelationshipsListItem: Swift.Equatable {
        public var ids: [Swift.String]?
        public var type: ComprehendClientTypes.RelationshipType?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case ids = "Ids"
            case type = "Type"
        }
    }
}

extension ComprehendClientTypes {
    public enum RelationshipType: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
        case child
        case sdkUnknown(Swift.String)

        public static var allCases: [RelationshipType] {
            return [
                .child,
                .sdkUnknown("")
            ]
        }
        public init?(rawValue: Swift.String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        public var rawValue: Swift.String {
            switch self {
            case .child: return "CHILD"
            case let .sdkUnknown(s): return s
            }
        }
        public init(from decoder: Swift.Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = RelationshipType(rawValue: rawValue) ?? RelationshipType.sdkUnknown(rawValue)
        }
    }
}

extension ComprehendClientTypes {
    public struct KeyPhrase: Swift.Equatable {
        public var beginOffset: Swift.Int?
        public var endOffset: Swift.Int?
        public var score: Swift.Float?
        public var text: Swift.String?
    }
}

extension ComprehendClientTypes {
    public enum LanguageCode: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
        case ar
        case de
        case en
        case es
        case fr
        case hi
        case it
        case ja
        case ko
        case pt
        case zh
        case zhTw
        case sdkUnknown(Swift.String)

        public static var allCases: [LanguageCode] {
            return [
                .ar,
                .de,
                .en,
                .es,
                .fr,
                .hi,
                .it,
                .ja,
                .ko,
                .pt,
                .zh,
                .zhTw,
                .sdkUnknown("")
            ]
        }
        public init?(rawValue: Swift.String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        public var rawValue: Swift.String {
            switch self {
            case .ar: return "ar"
            case .de: return "de"
            case .en: return "en"
            case .es: return "es"
            case .fr: return "fr"
            case .hi: return "hi"
            case .it: return "it"
            case .ja: return "ja"
            case .ko: return "ko"
            case .pt: return "pt"
            case .zh: return "zh"
            case .zhTw: return "zh-TW"
            case let .sdkUnknown(s): return s
            }
        }
        public init(from decoder: Swift.Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = LanguageCode(rawValue: rawValue) ?? LanguageCode.sdkUnknown(rawValue)
        }
    }
}

extension ComprehendClientTypes {
    public enum SyntaxLanguageCode: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
        case de
        case en
        case es
        case fr
        case it
        case pt
        case sdkUnknown(Swift.String)

        public static var allCases: [SyntaxLanguageCode] {
            return [
                .de,
                .en,
                .es,
                .fr,
                .it,
                .pt,
                .sdkUnknown("")
            ]
        }
        public init?(rawValue: Swift.String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        public var rawValue: Swift.String {
            switch self {
            case .de: return "de"
            case .en: return "en"
            case .es: return "es"
            case .fr: return "fr"
            case .it: return "it"
            case .pt: return "pt"
            case let .sdkUnknown(s): return s
            }
        }
        public init(from decoder: Swift.Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = SyntaxLanguageCode(rawValue: rawValue) ?? SyntaxLanguageCode.sdkUnknown(rawValue)
        }
    }
}

extension ComprehendClientTypes {
    public struct SyntaxToken: Swift.Equatable {
        public var beginOffset: Swift.Int?
        public var endOffset: Swift.Int?
        public var partOfSpeech: ComprehendClientTypes.PartOfSpeechTag?
        public var text: Swift.String?
        public var tokenId: Swift.Int?
    }
}


extension ComprehendClientTypes {
    public struct DominantLanguage: Swift.Equatable {
        public var languageCode: Swift.String?
        public var score: Swift.Float?
    }
}

extension ComprehendClientTypes {
    public struct PartOfSpeechTag: Swift.Equatable {
        public var score: Swift.Float?
        public var tag: ComprehendClientTypes.PartOfSpeechTagType?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case score = "Score"
            case tag = "Tag"
        }
    }
}

extension ComprehendClientTypes {
    public enum SentimentType: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
        case mixed
        case negative
        case neutral
        case positive
        case sdkUnknown(Swift.String)

        public static var allCases: [SentimentType] {
            return [
                .mixed,
                .negative,
                .neutral,
                .positive,
                .sdkUnknown("")
            ]
        }
        public init?(rawValue: Swift.String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        public var rawValue: Swift.String {
            switch self {
            case .mixed: return "MIXED"
            case .negative: return "NEGATIVE"
            case .neutral: return "NEUTRAL"
            case .positive: return "POSITIVE"
            case let .sdkUnknown(s): return s
            }
        }
        public init(from decoder: Swift.Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = SentimentType(rawValue: rawValue) ?? SentimentType.sdkUnknown(rawValue)
        }
    }
}

extension ComprehendClientTypes {
    public enum PartOfSpeechTagType: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
        case adj
        case adp
        case adv
        case aux
        case cconj
        case conj
        case det
        case intj
        case noun
        case num
        case o
        case part
        case pron
        case propn
        case punct
        case sconj
        case sym
        case verb
        case sdkUnknown(Swift.String)

        public static var allCases: [PartOfSpeechTagType] {
            return [
                .adj,
                .adp,
                .adv,
                .aux,
                .cconj,
                .conj,
                .det,
                .intj,
                .noun,
                .num,
                .o,
                .part,
                .pron,
                .propn,
                .punct,
                .sconj,
                .sym,
                .verb,
                .sdkUnknown("")
            ]
        }
        public init?(rawValue: Swift.String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        public var rawValue: Swift.String {
            switch self {
            case .adj: return "ADJ"
            case .adp: return "ADP"
            case .adv: return "ADV"
            case .aux: return "AUX"
            case .cconj: return "CCONJ"
            case .conj: return "CONJ"
            case .det: return "DET"
            case .intj: return "INTJ"
            case .noun: return "NOUN"
            case .num: return "NUM"
            case .o: return "O"
            case .part: return "PART"
            case .pron: return "PRON"
            case .propn: return "PROPN"
            case .punct: return "PUNCT"
            case .sconj: return "SCONJ"
            case .sym: return "SYM"
            case .verb: return "VERB"
            case let .sdkUnknown(s): return s
            }
        }
        public init(from decoder: Swift.Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = PartOfSpeechTagType(rawValue: rawValue) ?? PartOfSpeechTagType.sdkUnknown(rawValue)
        }
    }
}


extension ComprehendClientTypes {
    public enum EntityType: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
        case commercialItem
        case date
        case event
        case location
        case organization
        case other
        case person
        case quantity
        case title
        case sdkUnknown(Swift.String)

        public static var allCases: [EntityType] {
            return [
                .commercialItem,
                .date,
                .event,
                .location,
                .organization,
                .other,
                .person,
                .quantity,
                .title,
                .sdkUnknown("")
            ]
        }
        public init?(rawValue: Swift.String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        public var rawValue: Swift.String {
            switch self {
            case .commercialItem: return "COMMERCIAL_ITEM"
            case .date: return "DATE"
            case .event: return "EVENT"
            case .location: return "LOCATION"
            case .organization: return "ORGANIZATION"
            case .other: return "OTHER"
            case .person: return "PERSON"
            case .quantity: return "QUANTITY"
            case .title: return "TITLE"
            case let .sdkUnknown(s): return s
            }
        }
        public init(from decoder: Swift.Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = EntityType(rawValue: rawValue) ?? EntityType.sdkUnknown(rawValue)
        }
    }
}
