//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSTranslate
import Amplify

extension AWSTranslate.DetectedLanguageLowConfidenceException: PredictionsErrorConvertible {
    var predictionsError: PredictionsError {
        .service(.detectedLanguageLowConfidence)
    }
}

extension AWSTranslate.InternalServerException: PredictionsErrorConvertible {
    var predictionsError: PredictionsError {
        .service(.internalServerError)
    }
}


extension AWSTranslate.InvalidRequestException: PredictionsErrorConvertible {
    var predictionsError: PredictionsError {
        .service(.invalidRequest)
    }
}

extension AWSTranslate.ResourceNotFoundException: PredictionsErrorConvertible {
    var predictionsError: PredictionsError {
        .service(.resourceNotFound)
    }
}

extension AWSTranslate.TextSizeLimitExceededException: PredictionsErrorConvertible {
    var predictionsError: PredictionsError {
        .service(.textSizeLimitExceeded)
    }
}

extension AWSTranslate.TooManyRequestsException: PredictionsErrorConvertible {
    var predictionsError: PredictionsError {
        .service(.throttling)
    }
}

extension AWSTranslate.UnsupportedLanguagePairException: PredictionsErrorConvertible {
    var predictionsError: PredictionsError {
        .service(.unsupportedLanguagePair)
    }
}
