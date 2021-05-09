//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Sentiment Analysis result for Predictions category
public struct Sentiment {

    /// <#Description#>
    public let predominantSentiment: SentimentType

    /// <#Description#>
    public let sentimentScores: [SentimentType: Double]?

    /// <#Description#>
    /// - Parameters:
    ///   - predominantSentiment: <#predominantSentiment description#>
    ///   - sentimentScores: <#sentimentScores description#>
    public init(predominantSentiment: SentimentType,
                sentimentScores: [SentimentType: Double]?) {
        self.predominantSentiment = predominantSentiment
        self.sentimentScores = sentimentScores
    }
}

/// <#Description#>
public enum SentimentType: String {

    /// <#Description#>
    case unknown

    /// <#Description#>
    case positive

    /// <#Description#>
    case negative

    /// <#Description#>
    case neutral

    /// <#Description#>
    case mixed
}
