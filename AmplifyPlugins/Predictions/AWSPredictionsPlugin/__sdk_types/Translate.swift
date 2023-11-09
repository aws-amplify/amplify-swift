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

struct TranslateTextInput: Equatable, Encodable {
    var settings: TranslateClientTypes.TranslationSettings?
    /// This member is required.
    var sourceLanguageCode: String
    /// This member is required.
    var targetLanguageCode: String
    var terminologyNames: [String]?
    /// This member is required.
    var text: String

    enum CodingKeys: String, CodingKey {
        case settings = "Settings"
        case sourceLanguageCode = "SourceLanguageCode"
        case targetLanguageCode = "TargetLanguageCode"
        case terminologyNames = "TerminologyNames"
        case text = "Text"
    }
}

struct TranslateTextOutputResponse: Equatable, Decodable {
    var appliedSettings: TranslateClientTypes.TranslationSettings?
    var appliedTerminologies: [TranslateClientTypes.AppliedTerminology]?
    /// This member is required.
    var sourceLanguageCode: String
    /// This member is required.
    var targetLanguageCode: String
    /// This member is required.
    var translatedText: String

    enum CodingKeys: String, CodingKey {
        case appliedSettings = "AppliedSettings"
        case appliedTerminologies = "AppliedTerminologies"
        case sourceLanguageCode = "SourceLanguageCode"
        case targetLanguageCode = "TargetLanguageCode"
        case translatedText = "TranslatedText"
    }
}


enum TranslateClientTypes {}

extension TranslateClientTypes {
    struct AppliedTerminology: Equatable, Decodable {
        var name: String?
        var terms: [TranslateClientTypes.Term]?

        enum CodingKeys: String, CodingKey {
            case name = "Name"
            case terms = "Terms"
        }
    }
}

extension TranslateClientTypes {
    struct Term: Equatable, Decodable {
        var sourceText: String?
        var targetText: String?

        enum CodingKeys: String, CodingKey {
            case sourceText = "SourceText"
            case targetText = "TargetText"
        }
    }
}

extension TranslateClientTypes {
    struct TranslationSettings: Equatable, Codable {
        var formality: TranslateClientTypes.Formality?
        var profanity: TranslateClientTypes.Profanity?

        enum CodingKeys: String, CodingKey {
            case formality = "Formality"
            case profanity = "Profanity"
        }
    }
}

extension TranslateClientTypes {
    enum Profanity: Equatable, RawRepresentable, CaseIterable, Codable, Hashable {
        case mask
        case sdkUnknown(String)

        static var allCases: [Profanity] {
            return [
                .mask,
                .sdkUnknown("")
            ]
        }
        init?(rawValue: String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        var rawValue: String {
            switch self {
            case .mask: return "MASK"
            case let .sdkUnknown(s): return s
            }
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = Profanity(rawValue: rawValue) ?? Profanity.sdkUnknown(rawValue)
        }
    }
}

extension TranslateClientTypes {
    enum Formality: Equatable, RawRepresentable, CaseIterable, Codable, Hashable {
        case formal
        case informal
        case sdkUnknown(String)

        static var allCases: [Formality] {
            return [
                .formal,
                .informal,
                .sdkUnknown("")
            ]
        }
        init?(rawValue: String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        var rawValue: String {
            switch self {
            case .formal: return "FORMAL"
            case .informal: return "INFORMAL"
            case let .sdkUnknown(s): return s
            }
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = Formality(rawValue: rawValue) ?? Formality.sdkUnknown(rawValue)
        }
    }
}
