//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum TranscribeStreamingClientTypes {}

extension TranscribeStreamingClientTypes {
    struct TranscriptEvent: Equatable, Decodable {
        var transcript: TranscribeStreamingClientTypes.Transcript?

        enum CodingKeys: String, CodingKey {
            case transcript = "Transcript"
        }
    }
}

extension TranscribeStreamingClientTypes {
    struct Transcript: Equatable, Decodable {
        var results: [TranscribeStreamingClientTypes.Result]?

        enum CodingKeys: String, CodingKey {
            case results = "Results"
        }
    }
}

extension TranscribeStreamingClientTypes {
    struct Result: Equatable, Decodable {
        var alternatives: [TranscribeStreamingClientTypes.Alternative]?
        var channelId: String?
        var endTime: Double?
        var isPartial: Bool?
        var languageCode: TranscribeStreamingClientTypes.LanguageCode?
        var languageIdentification: [TranscribeStreamingClientTypes.LanguageWithScore]?
        var resultId: String?
        var startTime: Double?

        enum CodingKeys: String, CodingKey {
            case alternatives = "Alternatives"
            case channelId = "ChannelId"
            case endTime = "EndTime"
            case isPartial = "IsPartial"
            case languageCode = "LanguageCode"
            case languageIdentification = "LanguageIdentification"
            case resultId = "ResultId"
            case startTime = "StartTime"
        }
    }
}

extension TranscribeStreamingClientTypes {
    struct LanguageWithScore: Equatable, Decodable {
        var languageCode: TranscribeStreamingClientTypes.LanguageCode?
        var score: Double

        enum CodingKeys: String, CodingKey {
            case languageCode = "LanguageCode"
            case score = "Score"
        }
    }
}

extension TranscribeStreamingClientTypes {
    struct Alternative: Equatable, Decodable {
        var entities: [TranscribeStreamingClientTypes.Entity]?
        var items: [TranscribeStreamingClientTypes.Item]?
        var transcript: String?

        enum CodingKeys: String, CodingKey {
            case entities = "Entities"
            case items = "Items"
            case transcript = "Transcript"
        }
    }
}

extension TranscribeStreamingClientTypes {
    struct Item: Equatable, Decodable {
        var confidence: Double?
        var content: String?
        var endTime: Double
        var speaker: String?
        var stable: Bool?
        var startTime: Double
        var type: TranscribeStreamingClientTypes.ItemType?
        var vocabularyFilterMatch: Bool

        enum CodingKeys: String, CodingKey {
            case confidence = "Confidence"
            case content = "Content"
            case endTime = "EndTime"
            case speaker = "Speaker"
            case stable = "Stable"
            case startTime = "StartTime"
            case type = "Type"
            case vocabularyFilterMatch = "VocabularyFilterMatch"
        }
    }
}

extension TranscribeStreamingClientTypes {
    enum ItemType: Equatable, RawRepresentable, CaseIterable, Codable, Hashable {
        case pronunciation
        case punctuation
        case sdkUnknown(String)

        static var allCases: [ItemType] {
            return [
                .pronunciation,
                .punctuation,
                .sdkUnknown("")
            ]
        }
        init?(rawValue: String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        var rawValue: String {
            switch self {
            case .pronunciation: return "pronunciation"
            case .punctuation: return "punctuation"
            case let .sdkUnknown(s): return s
            }
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = ItemType(rawValue: rawValue) ?? ItemType.sdkUnknown(rawValue)
        }
    }
}


extension TranscribeStreamingClientTypes {
    struct Entity: Equatable, Decodable {
        var category: String?
        var confidence: Double?
        var content: String?
        var endTime: Double
        var startTime: Double
        var type: String?

        enum CodingKeys: String, CodingKey {
            case category = "Category"
            case confidence = "Confidence"
            case content = "Content"
            case endTime = "EndTime"
            case startTime = "StartTime"
            case type = "Type"
        }
    }
}

extension TranscribeStreamingClientTypes {
    enum MediaEncoding: Equatable, RawRepresentable, CaseIterable, Codable, Hashable {
        case flac
        case oggOpus
        case pcm
        case sdkUnknown(String)

        static var allCases: [MediaEncoding] {
            return [
                .flac,
                .oggOpus,
                .pcm,
                .sdkUnknown("")
            ]
        }
        init?(rawValue: String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        var rawValue: String {
            switch self {
            case .flac: return "flac"
            case .oggOpus: return "ogg-opus"
            case .pcm: return "pcm"
            case let .sdkUnknown(s): return s
            }
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = MediaEncoding(rawValue: rawValue) ?? MediaEncoding.sdkUnknown(rawValue)
        }
    }
}

extension TranscribeStreamingClientTypes {
    enum LanguageCode: Equatable, RawRepresentable, CaseIterable, Codable, Hashable {
        case deDe
        case enAu
        case enGb
        case enUs
        case esUs
        case frCa
        case frFr
        case hiIn
        case itIt
        case jaJp
        case koKr
        case ptBr
        case thTh
        case zhCn
        case sdkUnknown(String)

        static var allCases: [LanguageCode] {
            return [
                .deDe,
                .enAu,
                .enGb,
                .enUs,
                .esUs,
                .frCa,
                .frFr,
                .hiIn,
                .itIt,
                .jaJp,
                .koKr,
                .ptBr,
                .thTh,
                .zhCn,
                .sdkUnknown("")
            ]
        }
        init?(rawValue: String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        var rawValue: String {
            switch self {
            case .deDe: return "de-DE"
            case .enAu: return "en-AU"
            case .enGb: return "en-GB"
            case .enUs: return "en-US"
            case .esUs: return "es-US"
            case .frCa: return "fr-CA"
            case .frFr: return "fr-FR"
            case .hiIn: return "hi-IN"
            case .itIt: return "it-IT"
            case .jaJp: return "ja-JP"
            case .koKr: return "ko-KR"
            case .ptBr: return "pt-BR"
            case .thTh: return "th-TH"
            case .zhCn: return "zh-CN"
            case let .sdkUnknown(s): return s
            }
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = LanguageCode(rawValue: rawValue) ?? LanguageCode.sdkUnknown(rawValue)
        }
    }
}
