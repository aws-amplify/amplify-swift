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

public struct AnalyzeDocumentInput: Swift.Equatable {
    /// This member is required.
    public var document: TextractClientTypes.Document
    /// This member is required.
    public var featureTypes: [TextractClientTypes.FeatureType]
    public var humanLoopConfig: TextractClientTypes.HumanLoopConfig?
    public var queriesConfig: TextractClientTypes.QueriesConfig?

    enum CodingKeys: Swift.String, Swift.CodingKey {
        case document = "Document"
        case featureTypes = "FeatureTypes"
        case humanLoopConfig = "HumanLoopConfig"
        case queriesConfig = "QueriesConfig"
    }
}

public struct AnalyzeDocumentOutputResponse: Swift.Equatable {
    public var analyzeDocumentModelVersion: Swift.String?
    public var blocks: [TextractClientTypes.Block]?
    public var documentMetadata: TextractClientTypes.DocumentMetadata?
    public var humanLoopActivationOutput: TextractClientTypes.HumanLoopActivationOutput?

    enum CodingKeys: Swift.String, Swift.CodingKey {
        case analyzeDocumentModelVersion = "AnalyzeDocumentModelVersion"
        case blocks = "Blocks"
        case documentMetadata = "DocumentMetadata"
        case humanLoopActivationOutput = "HumanLoopActivationOutput"
    }
}

public struct DetectDocumentTextInput: Swift.Equatable {
    /// The input document as base64-encoded bytes or an Amazon S3 object. If you use the AWS CLI to call Amazon Textract operations, you can't pass image bytes. The document must be an image in JPEG or PNG format. If you're using an AWS SDK to call Amazon Textract, you might not need to base64-encode image bytes that are passed using the Bytes field.
    /// This member is required.
    public var document: TextractClientTypes.Document?

    enum CodingKeys: Swift.String, Swift.CodingKey {
        case document = "Document"
    }
}


public struct DetectDocumentTextOutputResponse: Swift.Equatable {
    /// An array of Block objects that contain the text that's detected in the document.
    public var blocks: [TextractClientTypes.Block]?
    ///
    public var detectDocumentTextModelVersion: Swift.String?
    /// Metadata about the document. It contains the number of pages that are detected in the document.
    public var documentMetadata: TextractClientTypes.DocumentMetadata?

    enum CodingKeys: Swift.String, Swift.CodingKey {
        case blocks = "Blocks"
        case detectDocumentTextModelVersion = "DetectDocumentTextModelVersion"
        case documentMetadata = "DocumentMetadata"
    }
}

public enum TextractClientTypes {}

extension TextractClientTypes {
    public struct HumanLoopActivationOutput: Swift.Equatable {
        public var humanLoopActivationConditionsEvaluationResults: Swift.String?
        public var humanLoopActivationReasons: [Swift.String]?
        public var humanLoopArn: Swift.String?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case humanLoopActivationConditionsEvaluationResults = "HumanLoopActivationConditionsEvaluationResults"
            case humanLoopActivationReasons = "HumanLoopActivationReasons"
            case humanLoopArn = "HumanLoopArn"
        }
    }
}

extension TextractClientTypes {
    public struct QueriesConfig: Swift.Equatable {
        /// This member is required.
        public var queries: [TextractClientTypes.Query]

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case queries = "Queries"
        }
    }
}

extension TextractClientTypes {
    public struct HumanLoopDataAttributes: Swift.Equatable {
        public var contentClassifiers: [TextractClientTypes.ContentClassifier]?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case contentClassifiers = "ContentClassifiers"
        }
    }
}

extension TextractClientTypes {
    public enum ContentClassifier: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
        case freeOfAdultContent
        case freeOfPersonallyIdentifiableInformation
        case sdkUnknown(Swift.String)

        public static var allCases: [ContentClassifier] {
            return [
                .freeOfAdultContent,
                .freeOfPersonallyIdentifiableInformation,
                .sdkUnknown("")
            ]
        }
        public init?(rawValue: Swift.String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        public var rawValue: Swift.String {
            switch self {
            case .freeOfAdultContent: return "FreeOfAdultContent"
            case .freeOfPersonallyIdentifiableInformation: return "FreeOfPersonallyIdentifiableInformation"
            case let .sdkUnknown(s): return s
            }
        }
        public init(from decoder: Swift.Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = ContentClassifier(rawValue: rawValue) ?? ContentClassifier.sdkUnknown(rawValue)
        }
    }
}

extension TextractClientTypes {
    public struct HumanLoopConfig: Swift.Equatable {
        public var dataAttributes: TextractClientTypes.HumanLoopDataAttributes?
        /// This member is required.
        public var flowDefinitionArn: Swift.String
        /// This member is required.
        public var humanLoopName: Swift.String

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case dataAttributes = "DataAttributes"
            case flowDefinitionArn = "FlowDefinitionArn"
            case humanLoopName = "HumanLoopName"
        }
    }
}

extension TextractClientTypes {
    public enum FeatureType: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
        case forms
        case queries
        case signatures
        case tables
        case sdkUnknown(Swift.String)

        public static var allCases: [FeatureType] {
            return [
                .forms,
                .queries,
                .signatures,
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
            case .queries: return "QUERIES"
            case .signatures: return "SIGNATURES"
            case .tables: return "TABLES"
            case let .sdkUnknown(s): return s
            }
        }
        public init(from decoder: Swift.Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = FeatureType(rawValue: rawValue) ?? FeatureType.sdkUnknown(rawValue)
        }
    }
}

extension TextractClientTypes {
    public enum BlockType: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
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
        case sdkUnknown(Swift.String)

        public static var allCases: [BlockType] {
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
        public init?(rawValue: Swift.String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        public var rawValue: Swift.String {
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
        public init(from decoder: Swift.Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = BlockType(rawValue: rawValue) ?? BlockType.sdkUnknown(rawValue)
        }
    }
}


extension TextractClientTypes {
    public struct Block: Swift.Equatable {
        public var blockType: TextractClientTypes.BlockType?
        public var columnIndex: Swift.Int?
        public var columnSpan: Swift.Int?
        public var confidence: Swift.Float?
        public var entityTypes: [TextractClientTypes.EntityType]?
        public var geometry: TextractClientTypes.Geometry?
        public var id: Swift.String?
        public var page: Swift.Int?
        public var query: TextractClientTypes.Query?
        public var relationships: [TextractClientTypes.Relationship]?
        public var rowIndex: Swift.Int?
        public var rowSpan: Swift.Int?
        public var selectionStatus: TextractClientTypes.SelectionStatus?
        public var text: Swift.String?
        public var textType: TextractClientTypes.TextType?

        enum CodingKeys: Swift.String, Swift.CodingKey {
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
    public enum TextType: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
        case handwriting
        case printed
        case sdkUnknown(Swift.String)

        public static var allCases: [TextType] {
            return [
                .handwriting,
                .printed,
                .sdkUnknown("")
            ]
        }
        public init?(rawValue: Swift.String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        public var rawValue: Swift.String {
            switch self {
            case .handwriting: return "HANDWRITING"
            case .printed: return "PRINTED"
            case let .sdkUnknown(s): return s
            }
        }
        public init(from decoder: Swift.Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = TextType(rawValue: rawValue) ?? TextType.sdkUnknown(rawValue)
        }
    }
}


extension TextractClientTypes {
    public enum SelectionStatus: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
        case notSelected
        case selected
        case sdkUnknown(Swift.String)

        public static var allCases: [SelectionStatus] {
            return [
                .notSelected,
                .selected,
                .sdkUnknown("")
            ]
        }
        public init?(rawValue: Swift.String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        public var rawValue: Swift.String {
            switch self {
            case .notSelected: return "NOT_SELECTED"
            case .selected: return "SELECTED"
            case let .sdkUnknown(s): return s
            }
        }
        public init(from decoder: Swift.Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = SelectionStatus(rawValue: rawValue) ?? SelectionStatus.sdkUnknown(rawValue)
        }
    }
}

extension TextractClientTypes {
    public struct Relationship: Swift.Equatable {
        public var ids: [Swift.String]?
        public var type: TextractClientTypes.RelationshipType?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case ids = "Ids"
            case type = "Type"
        }
    }
}

extension TextractClientTypes {
    public enum RelationshipType: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
        case answer
        case child
        case complexFeatures
        case mergedCell
        case table
        case tableFooter
        case tableTitle
        case title
        case value
        case sdkUnknown(Swift.String)

        public static var allCases: [RelationshipType] {
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
        public init?(rawValue: Swift.String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        public var rawValue: Swift.String {
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
        public init(from decoder: Swift.Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = RelationshipType(rawValue: rawValue) ?? RelationshipType.sdkUnknown(rawValue)
        }
    }
}

extension TextractClientTypes {
    public struct Query: Swift.Equatable {
        public var alias: Swift.String?
        public var pages: [Swift.String]?
        /// This member is required.
        public var text: Swift.String

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case alias = "Alias"
            case pages = "Pages"
            case text = "Text"
        }
    }

}

extension TextractClientTypes {
    public struct Geometry: Swift.Equatable {
        public var boundingBox: TextractClientTypes.BoundingBox?
        public var polygon: [TextractClientTypes.Point]?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case boundingBox = "BoundingBox"
            case polygon = "Polygon"
        }
    }
}

extension TextractClientTypes {
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

extension TextractClientTypes {
    public struct Point: Swift.Equatable {
        public var x: Swift.Float
        public var y: Swift.Float

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case x = "X"
            case y = "Y"
        }
    }
}

extension TextractClientTypes {
    public enum EntityType: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
        case columnHeader
        case key
        case semiStructuredTable
        case structuredTable
        case tableFooter
        case tableSectionTitle
        case tableSummary
        case tableTitle
        case value
        case sdkUnknown(Swift.String)

        public static var allCases: [EntityType] {
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
        public init?(rawValue: Swift.String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        public var rawValue: Swift.String {
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
        public init(from decoder: Swift.Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = EntityType(rawValue: rawValue) ?? EntityType.sdkUnknown(rawValue)
        }
    }
}

extension TextractClientTypes {
    public struct DocumentMetadata: Swift.Equatable {
        public var pages: Swift.Int?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case pages = "Pages"
        }
    }
}

extension TextractClientTypes {
    public struct Document: Swift.Equatable {
        public var bytes: Data?
        public var s3Object: TextractClientTypes.S3Object?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case bytes = "Bytes"
            case s3Object = "S3Object"
        }
    }
}

extension TextractClientTypes {
    public struct S3Object: Swift.Equatable {
        public var bucket: Swift.String?
        public var name: Swift.String?
        public var version: Swift.String?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case bucket = "Bucket"
            case name = "Name"
            case version = "Version"
        }
    }
}
