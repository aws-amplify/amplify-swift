//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSComprehend

extension AWSComprehendSentimentType {

    func toAmplifySentimentType() -> SentimentType {
        switch self {
        case .positive:
            return .positive
        case .neutral:
            return .neutral
        case .negative:
            return .negative
        case .mixed:
            return .mixed
        case .unknown:
            return .unknown
        @unknown default:
            return .unknown
        }
    }
}
