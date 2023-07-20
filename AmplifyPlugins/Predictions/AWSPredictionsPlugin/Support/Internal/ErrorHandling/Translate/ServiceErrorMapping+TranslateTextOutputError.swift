//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSTranslate
import Amplify

extension ServiceErrorMapping where T == TranslateTextOutputError {
    static let translateText: Self = .init { error in
        switch error {
        case .detectedLanguageLowConfidenceException(let detectedLanguageLowConfidenceException):
            return PredictionsError.service(.detectedLanguageLowConfidence)
        case .internalServerException(let internalServerException):
            return PredictionsError.service(.internalServerError)
        case .invalidRequestException(let invalidRequestException):
            return PredictionsError.service(.invalidRequest)
        case .resourceNotFoundException, .serviceUnavailableException:
            return PredictionsError.service(.resourceNotFound)
        case .textSizeLimitExceededException(let textSizeLimitExceededException):
            return PredictionsError.service(.textSizeLimitExceeded)
        case .tooManyRequestsException(let tooManyRequestsException):
            return PredictionsError.service(.throttling)
        case .unsupportedLanguagePairException(let unsupportedLanguagePairException):
            return PredictionsError.service(.unsupportedLanguagePair)
        case .unknown:
            return PredictionsError.unknownServiceError(error)
        }
    }
}
