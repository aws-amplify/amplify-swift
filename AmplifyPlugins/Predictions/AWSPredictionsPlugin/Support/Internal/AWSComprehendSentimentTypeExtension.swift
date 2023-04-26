//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSComprehend

extension ComprehendClientTypes.SentimentType {

    func toAmplifySentimentType() -> Predictions.Sentiment.Kind {
        switch self {
        case .positive:
            return .positive
        case .neutral:
            return .neutral
        case .negative:
            return .negative
        case .mixed:
            return .mixed
        case .sdkUnknown:
            return .unknown
        }
    }
}
