//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// Sentiment Analysis
public struct Sentiment {
    let predominantSentiment: SentimentType
    let sentimentScores: [SentimentType: Double]?

    public init(predominantSentiment: SentimentType,
                sentimentScores: [SentimentType: Double]?) {
        self.predominantSentiment = predominantSentiment
        self.sentimentScores = sentimentScores
    }
}

public enum SentimentType {
    case unknown
    case positive
    case negative
    case neutral
    case mixed
}
