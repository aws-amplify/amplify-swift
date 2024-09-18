//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSTranscribeStreaming
import Foundation

extension TranscribeStreamingClientTypes.TranscriptEvent: Decodable {
    private enum CodingKeys: String, CodingKey {
        case transcript = "Transcript"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            transcript: container.decode(
                TranscribeStreamingClientTypes.Transcript.self,
                forKey: .transcript
            )
        )
    }
}

extension TranscribeStreamingClientTypes.Transcript: Decodable {
    private enum CodingKeys: String, CodingKey {
        case results = "Results"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            results: container.decode([TranscribeStreamingClientTypes.Result].self, forKey: .results)
        )
    }
}

extension TranscribeStreamingClientTypes.Result: Decodable {
    private enum CodingKeys: String, CodingKey {
        case alternatives = "Alternatives"
        case channelId = "ChannelId"
        case endTime = "EndTime"
        case isPartial = "IsPartial"
        case languageCode = "LanguageCode"
        case languageIdentification = "LanguageIdentification"
        case resultId = "ResultId"
        case startTime = "StartTime"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            alternatives: container.decodeIfPresent(
                [TranscribeStreamingClientTypes.Alternative].self,
                forKey: .alternatives
            ),
            channelId: container.decodeIfPresent(String.self, forKey: .channelId),
            endTime: container.decode(Double.self, forKey: .endTime),
            isPartial: container.decode(Bool.self, forKey: .isPartial),
            languageCode: container.decodeIfPresent(
                TranscribeStreamingClientTypes.LanguageCode.self,
                forKey: .languageCode
            ),
            languageIdentification: container.decodeIfPresent(
                [TranscribeStreamingClientTypes.LanguageWithScore].self,
                forKey: .languageIdentification
            ),
            resultId: container.decodeIfPresent(String.self, forKey: .resultId),
            startTime: container.decode(Double.self, forKey: .startTime)
        )
    }
}

extension TranscribeStreamingClientTypes.Alternative: Decodable {
    private enum CodingKeys: String, CodingKey {
        case entities = "Entities"
        case items = "Items"
        case transcript = "Transcript"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            entities: container.decodeIfPresent(
                [TranscribeStreamingClientTypes.Entity].self,
                forKey: .entities
            ),
            items: container.decodeIfPresent(
                [TranscribeStreamingClientTypes.Item].self,
                forKey: .items
            ),
            transcript: container.decodeIfPresent(String.self, forKey: .transcript)
        )
    }
}

extension TranscribeStreamingClientTypes.Entity: Decodable {
    private enum CodingKeys: String, CodingKey {
        case category = "Category"
        case confidence = "Confidence"
        case content = "Content"
        case endTime = "EndTime"
        case startTime = "StartTime"
        case type = "Type"
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
    private enum CodingKeys: String, CodingKey {
        case confidence = "Confidence"
        case content = "Content"
        case endTime = "EndTime"
        case speaker = "Speaker"
        case stable = "Stable"
        case startTime = "StartTime"
        case type = "Type"
        case vocabularyFilterMatch = "VocabularyFilterMatch"
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
    private enum CodingKeys: String, CodingKey {
        case languageCode = "LanguageCode"
        case score = "Score"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            languageCode: container.decodeIfPresent(
                TranscribeStreamingClientTypes.LanguageCode.self,
                forKey: .languageCode
            ),
            score: container.decode(Double.self, forKey: .score)
        )
    }
}

extension TranscribeStreamingClientTypes.ItemType: Decodable {}

extension TranscribeStreamingClientTypes.LanguageCode: Decodable {}
