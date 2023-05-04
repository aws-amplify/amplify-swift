//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSRekognition
import Amplify

extension ServiceErrorMapping where T == DetectModerationLabelsOutputError {
    static let detectModerationLabels: Self = .init { error in
        switch error {
        case .accessDeniedException(let accessDeniedException):
            return PredictionsError.service(.accessDenied)
        case .imageTooLargeException(let imageTooLargeException):
            return RekognitionCommonExceptions.imageTooLarge(
                error, statusCode: imageTooLargeException._statusCode
            )
        case .internalServerError:
            return PredictionsError.service(.internalServerError)
        case .invalidImageFormatException(let invalidImageFormatException):
            return RekognitionCommonExceptions.invalidImageFormat(
                error,
                statusCode: invalidImageFormatException._statusCode
            )
        case .invalidParameterException(let invalidParameterException):
            return RekognitionCommonExceptions.invalidParameter(
                error,
                statusCode: invalidParameterException._statusCode
            )
        case .invalidS3ObjectException(let invalidS3ObjectException):
            return RekognitionCommonExceptions.invalidS3Object(
                error,
                statusCode: invalidS3ObjectException._statusCode
            )
        case .provisionedThroughputExceededException(let provisionedThroughputExceededException):
            return RekognitionCommonExceptions.provisionedThroughputExceeded(
                error,
                statusCode: provisionedThroughputExceededException._statusCode
            )
        case .throttlingException:
            return PredictionsError.service(.throttling)
        case .humanLoopQuotaExceededException(let humanLoopQuotaExceededException):
            return .service(
                .init(
                    description: "",
                    recoverySuggestion: "",
                    httpStatusCode: humanLoopQuotaExceededException._statusCode?.rawValue,
                    underlyingError: error
                )
            )
        case .unknown:
            return PredictionsError.unknownServiceError(error)
        }
    }
}
