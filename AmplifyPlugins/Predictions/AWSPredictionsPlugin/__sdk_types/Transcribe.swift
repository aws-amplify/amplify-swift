//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation



public enum TranscribeStreamingClientTypes {}

extension TranscribeStreamingClientTypes {
    public struct TranscriptEvent: Swift.Equatable {
        public var transcript: TranscribeStreamingClientTypes.Transcript?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case transcript = "Transcript"
        }
    }
}

extension TranscribeStreamingClientTypes {
    public struct Transcript: Swift.Equatable {
        public var results: [TranscribeStreamingClientTypes.Result]?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case results = "Results"
        }
    }
}

extension TranscribeStreamingClientTypes {
    public struct Result: Swift.Equatable {
        public var alternatives: [TranscribeStreamingClientTypes.Alternative]?
        public var channelId: Swift.String?
        public var endTime: Swift.Double?
        public var isPartial: Swift.Bool?
        public var languageCode: TranscribeStreamingClientTypes.LanguageCode?
        public var languageIdentification: [TranscribeStreamingClientTypes.LanguageWithScore]?
        public var resultId: Swift.String?
        public var startTime: Swift.Double?

        enum CodingKeys: Swift.String, Swift.CodingKey {
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
    public struct LanguageWithScore: Swift.Equatable {
        public var languageCode: TranscribeStreamingClientTypes.LanguageCode?
        public var score: Swift.Double

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case languageCode = "LanguageCode"
            case score = "Score"
        }
    }
}

extension TranscribeStreamingClientTypes {
    public struct Alternative: Swift.Equatable {
        public var entities: [TranscribeStreamingClientTypes.Entity]?
        public var items: [TranscribeStreamingClientTypes.Item]?
        public var transcript: Swift.String?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case entities = "Entities"
            case items = "Items"
            case transcript = "Transcript"
        }
    }
}

extension TranscribeStreamingClientTypes {
    public struct Item: Swift.Equatable {
        public var confidence: Swift.Double?
        public var content: Swift.String?
        public var endTime: Swift.Double
        public var speaker: Swift.String?
        public var stable: Swift.Bool?
        public var startTime: Swift.Double
        public var type: TranscribeStreamingClientTypes.ItemType?
        public var vocabularyFilterMatch: Swift.Bool

        enum CodingKeys: Swift.String, Swift.CodingKey {
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
    public enum ItemType: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
        case pronunciation
        case punctuation
        case sdkUnknown(Swift.String)

        public static var allCases: [ItemType] {
            return [
                .pronunciation,
                .punctuation,
                .sdkUnknown("")
            ]
        }
        public init?(rawValue: Swift.String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        public var rawValue: Swift.String {
            switch self {
            case .pronunciation: return "pronunciation"
            case .punctuation: return "punctuation"
            case let .sdkUnknown(s): return s
            }
        }
        public init(from decoder: Swift.Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = ItemType(rawValue: rawValue) ?? ItemType.sdkUnknown(rawValue)
        }
    }
}


extension TranscribeStreamingClientTypes {
    public struct Entity: Swift.Equatable {
        public var category: Swift.String?
        public var confidence: Swift.Double?
        public var content: Swift.String?
        public var endTime: Swift.Double
        public var startTime: Swift.Double
        public var type: Swift.String?

        enum CodingKeys: Swift.String, Swift.CodingKey {
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
    public enum MediaEncoding: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
        case flac
        case oggOpus
        case pcm
        case sdkUnknown(Swift.String)

        public static var allCases: [MediaEncoding] {
            return [
                .flac,
                .oggOpus,
                .pcm,
                .sdkUnknown("")
            ]
        }
        public init?(rawValue: Swift.String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        public var rawValue: Swift.String {
            switch self {
            case .flac: return "flac"
            case .oggOpus: return "ogg-opus"
            case .pcm: return "pcm"
            case let .sdkUnknown(s): return s
            }
        }
        public init(from decoder: Swift.Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = MediaEncoding(rawValue: rawValue) ?? MediaEncoding.sdkUnknown(rawValue)
        }
    }
}

extension TranscribeStreamingClientTypes {
    public enum LanguageCode: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
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
        case sdkUnknown(Swift.String)

        public static var allCases: [LanguageCode] {
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
        public init?(rawValue: Swift.String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        public var rawValue: Swift.String {
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
        public init(from decoder: Swift.Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = LanguageCode(rawValue: rawValue) ?? LanguageCode.sdkUnknown(rawValue)
        }
    }
}
