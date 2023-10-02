//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSComprehend
import Amplify

protocol PredictionsErrorConvertible {
    var predictionsError: PredictionsError { get }
}

extension AWSComprehend.InternalServerException: PredictionsErrorConvertible {
    var predictionsError: PredictionsError {
        .service(.internalServerError)
    }
}

extension AWSComprehend.InvalidRequestException: PredictionsErrorConvertible {
    var predictionsError: PredictionsError {
        .service(.invalidRequest)
    }
}

extension AWSComprehend.TextSizeLimitExceededException: PredictionsErrorConvertible {
    var predictionsError: PredictionsError {
        .service(.textSizeLimitExceeded)
    }
}
