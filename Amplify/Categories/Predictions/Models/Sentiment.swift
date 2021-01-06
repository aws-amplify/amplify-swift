//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Sentiment Analysis result for Predictions category
public struct Sentiment {

    public let predominantSentiment: SentimentType
    public let sentimentScores: [SentimentType: Double]?

    public init(predominantSentiment: SentimentType,
                sentimentScores: [SentimentType: Double]?) {
        self.predominantSentiment = predominantSentiment
        self.sentimentScores = sentimentScores
    }
}

public enum SentimentType: String {
    case unknown
    case positive
    case negative
    case neutral
    case mixed
}
