//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSTextract
import Amplify

extension ServiceErrorMapping where T == DetectDocumentTextOutputError {
    static let detectDocumentText: Self = .init { error in
        switch error {
        case .accessDeniedException(let accessDeniedException):
            return PredictionsError.service(.accessDenied)
        case .internalServerError:
            return PredictionsError.service(.internalServerError)
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
        case .unknown:
            return PredictionsError.unknownServiceError(error)
        case .badDocumentException(let badDocumentException):
            return TextractCommonException.badDocument(
                error, statusCode: badDocumentException._statusCode
            )
        case .documentTooLargeException(let documentTooLargeException):
            return TextractCommonException.documentTooLarge(
                error, statusCode: documentTooLargeException._statusCode
            )
        case .unsupportedDocumentException(let unsupportedDocumentException):
            return TextractCommonException.unsupportedDocument(
                error, statusCode: unsupportedDocumentException._statusCode
            )
        }
    }
}
