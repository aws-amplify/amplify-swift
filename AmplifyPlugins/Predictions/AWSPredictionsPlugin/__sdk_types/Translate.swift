//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum AWSTranslate {}

extension AWSTranslate {
    struct DetectedLanguageLowConfidenceException: Error {}
    struct InternalServerException: Error {}
    struct InvalidRequestException: Error {}
    struct ResourceNotFoundException: Error {}
    struct TextSizeLimitExceededException: Error {}
    struct TooManyRequestsException: Error {}
    struct UnsupportedLanguagePairException: Error {}
}

public struct TranslateTextInput: Swift.Equatable {
    public var settings: TranslateClientTypes.TranslationSettings?
    /// This member is required.
    public var sourceLanguageCode: Swift.String
    /// This member is required.
    public var targetLanguageCode: Swift.String
    public var terminologyNames: [Swift.String]?
    /// This member is required.
    public var text: Swift.String

    enum CodingKeys: Swift.String, Swift.CodingKey {
        case settings = "Settings"
        case sourceLanguageCode = "SourceLanguageCode"
        case targetLanguageCode = "TargetLanguageCode"
        case terminologyNames = "TerminologyNames"
        case text = "Text"
    }
}

public struct TranslateTextOutputResponse: Swift.Equatable {
    public var appliedSettings: TranslateClientTypes.TranslationSettings?
    public var appliedTerminologies: [TranslateClientTypes.AppliedTerminology]?
    /// This member is required.
    public var sourceLanguageCode: Swift.String
    /// This member is required.
    public var targetLanguageCode: Swift.String
    /// This member is required.
    public var translatedText: Swift.String

    enum CodingKeys: Swift.String, Swift.CodingKey {
        case appliedSettings = "AppliedSettings"
        case appliedTerminologies = "AppliedTerminologies"
        case sourceLanguageCode = "SourceLanguageCode"
        case targetLanguageCode = "TargetLanguageCode"
        case translatedText = "TranslatedText"
    }
}


public enum TranslateClientTypes {}

extension TranslateClientTypes {
    public struct AppliedTerminology: Swift.Equatable {
        public var name: Swift.String?
        public var terms: [TranslateClientTypes.Term]?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case name = "Name"
            case terms = "Terms"
        }
    }
}

extension TranslateClientTypes {
    public struct Term: Swift.Equatable {
        public var sourceText: Swift.String?
        public var targetText: Swift.String?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case sourceText = "SourceText"
            case targetText = "TargetText"
        }
    }
}

extension TranslateClientTypes {
    public struct TranslationSettings: Swift.Equatable {
        public var formality: TranslateClientTypes.Formality?
        public var profanity: TranslateClientTypes.Profanity?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case formality = "Formality"
            case profanity = "Profanity"
        }
    }
}

extension TranslateClientTypes {
    public enum Profanity: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
        case mask
        case sdkUnknown(Swift.String)

        public static var allCases: [Profanity] {
            return [
                .mask,
                .sdkUnknown("")
            ]
        }
        public init?(rawValue: Swift.String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        public var rawValue: Swift.String {
            switch self {
            case .mask: return "MASK"
            case let .sdkUnknown(s): return s
            }
        }
        public init(from decoder: Swift.Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = Profanity(rawValue: rawValue) ?? Profanity.sdkUnknown(rawValue)
        }
    }
}

extension TranslateClientTypes {
    public enum Formality: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
        case formal
        case informal
        case sdkUnknown(Swift.String)

        public static var allCases: [Formality] {
            return [
                .formal,
                .informal,
                .sdkUnknown("")
            ]
        }
        public init?(rawValue: Swift.String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        public var rawValue: Swift.String {
            switch self {
            case .formal: return "FORMAL"
            case .informal: return "INFORMAL"
            case let .sdkUnknown(s): return s
            }
        }
        public init(from decoder: Swift.Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = Formality(rawValue: rawValue) ?? Formality.sdkUnknown(rawValue)
        }
    }
}
