//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum AWSTextract {}

extension AWSTextract {
    struct HumanLoopQuotaExceededException: Error {}
    struct ThrottlingException: Error {}
    struct InternalServerError: Error {}
    struct AccessDeniedException: Error {}
    struct InvalidParameterException: Error {}
    struct InvalidS3ObjectException: Error {}
    struct ProvisionedThroughputExceededException: Error {}
    struct BadDocumentException: Error {}
    struct DocumentTooLargeException: Error {}
    struct UnsupportedDocumentException: Error {}
}

struct AnalyzeDocumentInput: Equatable {
    /// This member is required.
    var document: TextractClientTypes.Document
    /// This member is required.
    var featureTypes: [TextractClientTypes.FeatureType]
    var humanLoopConfig: TextractClientTypes.HumanLoopConfig?
    var queriesConfig: TextractClientTypes.QueriesConfig?

    enum CodingKeys: String, CodingKey {
        case document = "Document"
        case featureTypes = "FeatureTypes"
        case humanLoopConfig = "HumanLoopConfig"
        case queriesConfig = "QueriesConfig"
    }
}

struct AnalyzeDocumentOutputResponse: Equatable {
    var analyzeDocumentModelVersion: String?
    var blocks: [TextractClientTypes.Block]?
    var documentMetadata: TextractClientTypes.DocumentMetadata?
    var humanLoopActivationOutput: TextractClientTypes.HumanLoopActivationOutput?

    enum CodingKeys: String, CodingKey {
        case analyzeDocumentModelVersion = "AnalyzeDocumentModelVersion"
        case blocks = "Blocks"
        case documentMetadata = "DocumentMetadata"
        case humanLoopActivationOutput = "HumanLoopActivationOutput"
    }
}

struct DetectDocumentTextInput: Equatable {
    /// The input document as base64-encoded bytes or an Amazon S3 object. If you use the AWS CLI to call Amazon Textract operations, you can't pass image bytes. The document must be an image in JPEG or PNG format. If you're using an AWS SDK to call Amazon Textract, you might not need to base64-encode image bytes that are passed using the Bytes field.
    /// This member is required.
    var document: TextractClientTypes.Document?

    enum CodingKeys: String, CodingKey {
        case document = "Document"
    }
}


struct DetectDocumentTextOutputResponse: Equatable {
    /// An array of Block objects that contain the text that's detected in the document.
    var blocks: [TextractClientTypes.Block]?
    ///
    var detectDocumentTextModelVersion: String?
    /// Metadata about the document. It contains the number of pages that are detected in the document.
    var documentMetadata: TextractClientTypes.DocumentMetadata?

    enum CodingKeys: String, CodingKey {
        case blocks = "Blocks"
        case detectDocumentTextModelVersion = "DetectDocumentTextModelVersion"
        case documentMetadata = "DocumentMetadata"
    }
}

enum TextractClientTypes {}

extension TextractClientTypes {
    struct HumanLoopActivationOutput: Equatable {
        var humanLoopActivationConditionsEvaluationResults: String?
        var humanLoopActivationReasons: [String]?
        var humanLoopArn: String?

        enum CodingKeys: String, CodingKey {
            case humanLoopActivationConditionsEvaluationResults = "HumanLoopActivationConditionsEvaluationResults"
            case humanLoopActivationReasons = "HumanLoopActivationReasons"
            case humanLoopArn = "HumanLoopArn"
        }
    }
}

extension TextractClientTypes {
    struct QueriesConfig: Equatable {
        /// This member is required.
        var queries: [TextractClientTypes.Query]

        enum CodingKeys: String, CodingKey {
            case queries = "Queries"
        }
    }
}

extension TextractClientTypes {
    struct HumanLoopDataAttributes: Equatable {
        var contentClassifiers: [TextractClientTypes.ContentClassifier]?

        enum CodingKeys: String, CodingKey {
            case contentClassifiers = "ContentClassifiers"
        }
    }
}

extension TextractClientTypes {
    enum ContentClassifier: Equatable, RawRepresentable, CaseIterable, Codable, Hashable {
        case freeOfAdultContent
        case freeOfPersonallyIdentifiableInformation
        case sdkUnknown(String)

        static var allCases: [ContentClassifier] {
            return [
                .freeOfAdultContent,
                .freeOfPersonallyIdentifiableInformation,
                .sdkUnknown("")
            ]
        }
        init?(rawValue: String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        var rawValue: String {
            switch self {
            case .freeOfAdultContent: return "FreeOfAdultContent"
            case .freeOfPersonallyIdentifiableInformation: return "FreeOfPersonallyIdentifiableInformation"
            case let .sdkUnknown(s): return s
            }
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = ContentClassifier(rawValue: rawValue) ?? ContentClassifier.sdkUnknown(rawValue)
        }
    }
}

extension TextractClientTypes {
    struct HumanLoopConfig: Equatable {
        var dataAttributes: TextractClientTypes.HumanLoopDataAttributes?
        /// This member is required.
        var flowDefinitionArn: String
        /// This member is required.
        var humanLoopName: String

        enum CodingKeys: String, CodingKey {
            case dataAttributes = "DataAttributes"
            case flowDefinitionArn = "FlowDefinitionArn"
            case humanLoopName = "HumanLoopName"
        }
    }
}

extension TextractClientTypes {
    enum FeatureType: Equatable, RawRepresentable, CaseIterable, Codable, Hashable {
        case forms
        case queries
        case signatures
        case tables
        case sdkUnknown(String)

        static var allCases: [FeatureType] {
            return [
                .forms,
                .queries,
                .signatures,
                .tables,
                .sdkUnknown("")
            ]
        }
        init?(rawValue: String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        var rawValue: String {
            switch self {
            case .forms: return "FORMS"
            case .queries: return "QUERIES"
            case .signatures: return "SIGNATURES"
            case .tables: return "TABLES"
            case let .sdkUnknown(s): return s
            }
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = FeatureType(rawValue: rawValue) ?? FeatureType.sdkUnknown(rawValue)
        }
    }
}

extension TextractClientTypes {
    enum BlockType: Equatable, RawRepresentable, CaseIterable, Codable, Hashable {
        case cell
        case keyValueSet
        case line
        case mergedCell
        case page
        case query
        case queryResult
        case selectionElement
        case signature
        case table
        case tableFooter
        case tableTitle
        case title
        case word
        case sdkUnknown(String)

        static var allCases: [BlockType] {
            return [
                .cell,
                .keyValueSet,
                .line,
                .mergedCell,
                .page,
                .query,
                .queryResult,
                .selectionElement,
                .signature,
                .table,
                .tableFooter,
                .tableTitle,
                .title,
                .word,
                .sdkUnknown("")
            ]
        }
        init?(rawValue: String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        var rawValue: String {
            switch self {
            case .cell: return "CELL"
            case .keyValueSet: return "KEY_VALUE_SET"
            case .line: return "LINE"
            case .mergedCell: return "MERGED_CELL"
            case .page: return "PAGE"
            case .query: return "QUERY"
            case .queryResult: return "QUERY_RESULT"
            case .selectionElement: return "SELECTION_ELEMENT"
            case .signature: return "SIGNATURE"
            case .table: return "TABLE"
            case .tableFooter: return "TABLE_FOOTER"
            case .tableTitle: return "TABLE_TITLE"
            case .title: return "TITLE"
            case .word: return "WORD"
            case let .sdkUnknown(s): return s
            }
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = BlockType(rawValue: rawValue) ?? BlockType.sdkUnknown(rawValue)
        }
    }
}


extension TextractClientTypes {
    struct Block: Equatable {
        var blockType: TextractClientTypes.BlockType?
        var columnIndex: Int?
        var columnSpan: Int?
        var confidence: Float?
        var entityTypes: [TextractClientTypes.EntityType]?
        var geometry: TextractClientTypes.Geometry?
        var id: String?
        var page: Int?
        var query: TextractClientTypes.Query?
        var relationships: [TextractClientTypes.Relationship]?
        var rowIndex: Int?
        var rowSpan: Int?
        var selectionStatus: TextractClientTypes.SelectionStatus?
        var text: String?
        var textType: TextractClientTypes.TextType?

        enum CodingKeys: String, CodingKey {
            case blockType = "BlockType"
            case columnIndex = "ColumnIndex"
            case columnSpan = "ColumnSpan"
            case confidence = "Confidence"
            case entityTypes = "EntityTypes"
            case geometry = "Geometry"
            case id = "Id"
            case page = "Page"
            case query = "Query"
            case relationships = "Relationships"
            case rowIndex = "RowIndex"
            case rowSpan = "RowSpan"
            case selectionStatus = "SelectionStatus"
            case text = "Text"
            case textType = "TextType"
        }
    }
}

extension TextractClientTypes {
    enum TextType: Equatable, RawRepresentable, CaseIterable, Codable, Hashable {
        case handwriting
        case printed
        case sdkUnknown(String)

        static var allCases: [TextType] {
            return [
                .handwriting,
                .printed,
                .sdkUnknown("")
            ]
        }
        init?(rawValue: String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        var rawValue: String {
            switch self {
            case .handwriting: return "HANDWRITING"
            case .printed: return "PRINTED"
            case let .sdkUnknown(s): return s
            }
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = TextType(rawValue: rawValue) ?? TextType.sdkUnknown(rawValue)
        }
    }
}


extension TextractClientTypes {
    enum SelectionStatus: Equatable, RawRepresentable, CaseIterable, Codable, Hashable {
        case notSelected
        case selected
        case sdkUnknown(String)

        static var allCases: [SelectionStatus] {
            return [
                .notSelected,
                .selected,
                .sdkUnknown("")
            ]
        }
        init?(rawValue: String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        var rawValue: String {
            switch self {
            case .notSelected: return "NOT_SELECTED"
            case .selected: return "SELECTED"
            case let .sdkUnknown(s): return s
            }
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = SelectionStatus(rawValue: rawValue) ?? SelectionStatus.sdkUnknown(rawValue)
        }
    }
}

extension TextractClientTypes {
    struct Relationship: Equatable {
        var ids: [String]?
        var type: TextractClientTypes.RelationshipType?

        enum CodingKeys: String, CodingKey {
            case ids = "Ids"
            case type = "Type"
        }
    }
}

extension TextractClientTypes {
    enum RelationshipType: Equatable, RawRepresentable, CaseIterable, Codable, Hashable {
        case answer
        case child
        case complexFeatures
        case mergedCell
        case table
        case tableFooter
        case tableTitle
        case title
        case value
        case sdkUnknown(String)

        static var allCases: [RelationshipType] {
            return [
                .answer,
                .child,
                .complexFeatures,
                .mergedCell,
                .table,
                .tableFooter,
                .tableTitle,
                .title,
                .value,
                .sdkUnknown("")
            ]
        }
        init?(rawValue: String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        var rawValue: String {
            switch self {
            case .answer: return "ANSWER"
            case .child: return "CHILD"
            case .complexFeatures: return "COMPLEX_FEATURES"
            case .mergedCell: return "MERGED_CELL"
            case .table: return "TABLE"
            case .tableFooter: return "TABLE_FOOTER"
            case .tableTitle: return "TABLE_TITLE"
            case .title: return "TITLE"
            case .value: return "VALUE"
            case let .sdkUnknown(s): return s
            }
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = RelationshipType(rawValue: rawValue) ?? RelationshipType.sdkUnknown(rawValue)
        }
    }
}

extension TextractClientTypes {
    struct Query: Equatable {
        var alias: String?
        var pages: [String]?
        /// This member is required.
        var text: String

        enum CodingKeys: String, CodingKey {
            case alias = "Alias"
            case pages = "Pages"
            case text = "Text"
        }
    }

}

extension TextractClientTypes {
    struct Geometry: Equatable {
        var boundingBox: TextractClientTypes.BoundingBox?
        var polygon: [TextractClientTypes.Point]?

        enum CodingKeys: String, CodingKey {
            case boundingBox = "BoundingBox"
            case polygon = "Polygon"
        }
    }
}

extension TextractClientTypes {
    struct BoundingBox: Equatable {
        var height: Float?
        var `left`: Float?
        var top: Float?
        var width: Float?

        enum CodingKeys: String, CodingKey {
            case height = "Height"
            case `left` = "Left"
            case top = "Top"
            case width = "Width"
        }
    }
}

extension TextractClientTypes {
    struct Point: Equatable {
        var x: Float
        var y: Float

        enum CodingKeys: String, CodingKey {
            case x = "X"
            case y = "Y"
        }
    }
}

extension TextractClientTypes {
    enum EntityType: Equatable, RawRepresentable, CaseIterable, Codable, Hashable {
        case columnHeader
        case key
        case semiStructuredTable
        case structuredTable
        case tableFooter
        case tableSectionTitle
        case tableSummary
        case tableTitle
        case value
        case sdkUnknown(String)

        static var allCases: [EntityType] {
            return [
                .columnHeader,
                .key,
                .semiStructuredTable,
                .structuredTable,
                .tableFooter,
                .tableSectionTitle,
                .tableSummary,
                .tableTitle,
                .value,
                .sdkUnknown("")
            ]
        }
        init?(rawValue: String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        var rawValue: String {
            switch self {
            case .columnHeader: return "COLUMN_HEADER"
            case .key: return "KEY"
            case .semiStructuredTable: return "SEMI_STRUCTURED_TABLE"
            case .structuredTable: return "STRUCTURED_TABLE"
            case .tableFooter: return "TABLE_FOOTER"
            case .tableSectionTitle: return "TABLE_SECTION_TITLE"
            case .tableSummary: return "TABLE_SUMMARY"
            case .tableTitle: return "TABLE_TITLE"
            case .value: return "VALUE"
            case let .sdkUnknown(s): return s
            }
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = EntityType(rawValue: rawValue) ?? EntityType.sdkUnknown(rawValue)
        }
    }
}

extension TextractClientTypes {
    struct DocumentMetadata: Equatable {
        var pages: Int?

        enum CodingKeys: String, CodingKey {
            case pages = "Pages"
        }
    }
}

extension TextractClientTypes {
    struct Document: Equatable {
        var bytes: Data?
        var s3Object: TextractClientTypes.S3Object?

        enum CodingKeys: String, CodingKey {
            case bytes = "Bytes"
            case s3Object = "S3Object"
        }
    }
}

extension TextractClientTypes {
    struct S3Object: Equatable {
        var bucket: String?
        var name: String?
        var version: String?

        enum CodingKeys: String, CodingKey {
            case bucket = "Bucket"
            case name = "Name"
            case version = "Version"
        }
    }
}
