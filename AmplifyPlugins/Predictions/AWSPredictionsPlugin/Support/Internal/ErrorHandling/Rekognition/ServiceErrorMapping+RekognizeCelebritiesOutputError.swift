//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSRekognition
import Amplify

extension ServiceErrorMapping where T == RecognizeCelebritiesOutputError {
    static let detectCelebrities: Self = .init { error in
        switch error {
        case .accessDeniedException(let accessDeniedException):
            return PredictionsError.service(.accessDenied)
        case .imageTooLargeException(let imageTooLargeException):
            return RekognitionCommonExceptions.imageTooLarge(error, statusCode: imageTooLargeException._statusCode)
        case .internalServerError(let internalServerError):
            return PredictionsError.service(.internalServerError)
        case .invalidImageFormatException(let invalidImageFormatException):
            return RekognitionCommonExceptions.invalidImageFormat(
                error, statusCode: invalidImageFormatException._statusCode
            )
        case .invalidParameterException(let invalidParameterException):
            return RekognitionCommonExceptions.invalidParameter(
                error, statusCode: invalidParameterException._statusCode
            )
        case .invalidS3ObjectException(let invalidS3ObjectException):
            return RekognitionCommonExceptions.invalidS3Object(
                error, statusCode: invalidS3ObjectException._statusCode
            )
        case .provisionedThroughputExceededException(let provisionedThroughputExceededException):
            return RekognitionCommonExceptions.provisionedThroughputExceeded(
                error, statusCode: provisionedThroughputExceededException._statusCode
            )
        case .throttlingException(let throttlingException):
            return PredictionsError.service(.throttling)
        case .unknown(let unknown):
            return PredictionsError.unknownServiceError(error)
        }
    }
}
