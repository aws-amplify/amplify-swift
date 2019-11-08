//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// Sentiment Analysis
public struct Sentiment {
    let predominantSentiment: String
    let sentimentScores: [String: Float]?
}
