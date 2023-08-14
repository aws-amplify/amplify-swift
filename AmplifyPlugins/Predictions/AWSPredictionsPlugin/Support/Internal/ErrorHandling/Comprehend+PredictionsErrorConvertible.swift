//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSComprehend
import Amplify

protocol PredictionsErrorConvertible {
    var fallbackDescription: String { get }
    var predictionsError: PredictionsError { get }
}

extension AWSComprehend.InternalServerException: PredictionsErrorConvertible {
    var fallbackDescription: String { "" }

    var predictionsError: PredictionsError {
        .service(.internalServerError)
    }
}

extension AWSComprehend.InvalidRequestException: PredictionsErrorConvertible {
    var fallbackDescription: String { "" }

    var predictionsError: PredictionsError {
        .service(.invalidRequest)
    }
}

extension AWSComprehend.TextSizeLimitExceededException: PredictionsErrorConvertible {
    var fallbackDescription: String { "" }

    var predictionsError: PredictionsError {
        .service(.textSizeLimitExceeded)
    }
}
