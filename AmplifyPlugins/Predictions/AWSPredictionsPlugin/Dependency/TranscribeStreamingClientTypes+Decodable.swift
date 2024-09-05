//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSTranscribeStreaming

extension TranscribeStreamingClientTypes.TranscriptEvent: Decodable {
    private enum CodingKeys: CodingKey {
        case transcript
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            transcript: container.decode(TranscribeStreamingClientTypes.Transcript.self, forKey: .transcript)
        )
    }
}

extension TranscribeStreamingClientTypes.Transcript: Decodable {
    private enum CodingKeys: CodingKey {
        case results
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            results: container.decode([TranscribeStreamingClientTypes.Result].self, forKey: .results)
        )
    }
}

extension TranscribeStreamingClientTypes.Result: Decodable {
    private enum CodingKeys: CodingKey {
        case alternatives
        case channelId
        case endTime
        case isPartial
        case languageCode
        case languageIdentification
        case resultId
        case startTime
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            alternatives: container.decodeIfPresent([TranscribeStreamingClientTypes.Alternative].self, forKey: .alternatives),
            channelId: container.decodeIfPresent(String.self, forKey: .channelId),
            endTime: container.decode(Double.self, forKey: .endTime),
            isPartial: container.decode(Bool.self, forKey: .isPartial),
            languageCode: container.decodeIfPresent(TranscribeStreamingClientTypes.LanguageCode.self, forKey: .languageCode),
            languageIdentification: container.decodeIfPresent([TranscribeStreamingClientTypes.LanguageWithScore].self, forKey: .languageIdentification),
            resultId: container.decodeIfPresent(String.self, forKey: .resultId),
            startTime: container.decode(Double.self, forKey: .startTime)
        )
    }
}

extension TranscribeStreamingClientTypes.Alternative: Decodable {
    private enum CodingKeys: CodingKey {
        case entities
        case items
        case transcript
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            entities: container.decodeIfPresent([TranscribeStreamingClientTypes.Entity].self, forKey: .entities),
            items: container.decodeIfPresent([TranscribeStreamingClientTypes.Item].self, forKey: .items),
            transcript: container.decodeIfPresent(String.self, forKey: .transcript)
        )
    }
}

extension TranscribeStreamingClientTypes.Entity: Decodable {
    private enum CodingKeys: CodingKey {
        case category
        case confidence
        case content
        case endTime
        case startTime
        case type
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            category: container.decodeIfPresent(String.self, forKey: .category),
            confidence: container.decodeIfPresent(Double.self, forKey: .confidence),
            content: container.decodeIfPresent(String.self, forKey: .content),
            endTime: container.decode(Double.self, forKey: .endTime),
            startTime: container.decode(Double.self, forKey: .startTime),
            type: container.decodeIfPresent(String.self, forKey: .type)
        )
    }
}

extension TranscribeStreamingClientTypes.Item: Decodable {
    private enum CodingKeys: CodingKey {
        case confidence
        case content
        case endTime
        case speaker
        case stable
        case startTime
        case type
        case vocabularyFilterMatch
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            confidence: container.decodeIfPresent(Double.self, forKey: .confidence),
            content: container.decodeIfPresent(String.self, forKey: .content),
            endTime: container.decode(Double.self, forKey: .endTime),
            speaker: container.decodeIfPresent(String.self, forKey: .speaker),
            stable: container.decodeIfPresent(Bool.self, forKey: .stable),
            startTime: container.decode(Double.self, forKey: .startTime),
            type: container.decodeIfPresent(TranscribeStreamingClientTypes.ItemType.self, forKey: .type),
            vocabularyFilterMatch: container.decode(Bool.self, forKey: .vocabularyFilterMatch)
        )
    }
}

extension TranscribeStreamingClientTypes.LanguageWithScore: Decodable {
    private enum CodingKeys: CodingKey {
        case languageCode
        case score
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            languageCode: container.decodeIfPresent(TranscribeStreamingClientTypes.LanguageCode.self, forKey: .languageCode),
            score: container.decode(Double.self, forKey: .score)
        )
    }
}

extension TranscribeStreamingClientTypes.ItemType: Decodable {}

extension TranscribeStreamingClientTypes.LanguageCode: Decodable {}
