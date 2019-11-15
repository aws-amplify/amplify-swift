//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSRekognition
import AWSTextract
import AWSPolly


class PredictionsErrorHelper {

    static func mapHttpResponseCode(statusCode: Int, serviceKey: String) -> PredictionsError? {
        if statusCode >= 200 && statusCode <= 299 {
            return nil
        }

        if statusCode == 404 {

        }
        // TODO status error mapper
        return PredictionsError.httpStatusError(statusCode, "TODO some status code to recovery message mapper")
    }

    static func mapServiceError(_ error: NSError) -> PredictionsError {
        let defaultError = PredictionsErrorHelper.getDefaultError(error)

        guard error.domain == AWSServiceErrorDomain else {
            return defaultError
        }

        let errorTypeOptional = AWSServiceErrorType.init(rawValue: error.code)
        guard let errorType = errorTypeOptional else {
            return defaultError
        }

        return PredictionsErrorHelper.map(errorType) ?? defaultError
    }

    static func mapRekognitionError(_ error: NSError) -> PredictionsError {
        let defaultError = PredictionsErrorHelper.getDefaultError(error)

        if error.domain == AWSServiceErrorDomain {
            return PredictionsErrorHelper.mapServiceError(error)
        }

        guard error.domain == AWSRekognitionErrorDomain else {
            return defaultError
        }

        guard let errorType = AWSRekognitionErrorType.init(rawValue: error.code) else {
            return defaultError
        }

        return PredictionsErrorHelper.map(errorType) ?? defaultError
    }

    static func mapTextractError(_ error: NSError) -> PredictionsError {
        let defaultError = PredictionsErrorHelper.getDefaultError(error)

        if error.domain == AWSServiceErrorDomain {
            return PredictionsErrorHelper.mapServiceError(error)
        }

        guard error.domain == AWSTextractErrorDomain else {
            return defaultError
        }

        guard let errorType = AWSTextractErrorType.init(rawValue: error.code) else {
            return defaultError
        }

        return PredictionsErrorHelper.map(errorType) ?? defaultError
    }

    static func mapPollyError(_ error: NSError) -> PredictionsError {
        let defaultError = PredictionsErrorHelper.getDefaultError(error)

        if error.domain == AWSServiceErrorDomain {
            return PredictionsErrorHelper.mapServiceError(error)
        }

        guard error.domain == AWSPollyErrorDomain else {
            return defaultError
        }

        guard let errorType = AWSPollyErrorType.init(rawValue: error.code) else {
            return defaultError
        }

        return PredictionsErrorHelper.map(errorType) ?? defaultError
    }

    static func getDefaultError(_ error: NSError) -> PredictionsError {
        let errorMessage = """
        Domain: [\(error.domain)
        Code: [\(error.code)
        LocalizedDescription: [\(error.localizedDescription)
        LocalizedFailureReason: [\(error.localizedFailureReason ?? "")
        LocalizedRecoverySuggestion: [\(error.localizedRecoverySuggestion ?? "")
        """

        return PredictionsError.unknownError(errorMessage, "")
    }

    // swiftlint:disable cyclomatic_complexity
    static func map(_ errorType: AWSServiceErrorType) -> PredictionsError? {
        switch errorType {
        case .unknown:
            break
        case .requestTimeTooSkewed:
            break
        case .invalidSignatureException:
            break
        case .signatureDoesNotMatch:
            break
        case .requestExpired:
            break
        case .authFailure:
            break
        case .accessDeniedException:
            return PredictionsError.accessDenied(PredictionsServiceErrorMessage.accessDenied.errorDescription,
                                                 PredictionsServiceErrorMessage.accessDenied.recoverySuggestion)
        case .unrecognizedClientException:
            break
        case .incompleteSignature:
            break
        case .invalidClientTokenId:
            break
        case .missingAuthenticationToken:
            break
        case .accessDenied:
            return PredictionsError.accessDenied(PredictionsServiceErrorMessage.accessDenied.errorDescription,
                                                 PredictionsServiceErrorMessage.accessDenied.recoverySuggestion)
        case .expiredToken:
            break
        case .invalidAccessKeyId:
            break
        case .invalidToken:
            break
        case .tokenRefreshRequired:
            break
        case .accessFailure:
            return PredictionsError.accessDenied(PredictionsServiceErrorMessage.accessDenied.errorDescription,
                                                 PredictionsServiceErrorMessage.accessDenied.recoverySuggestion)
        case .authMissingFailure:
            break
        case .throttling:
            break
        case .throttlingException:
            break
        @unknown default:
            break
        }

        return nil
    }

    //TODO fill in proper error messages for rekognition, textract and polly
    static func map(_ errorType: AWSRekognitionErrorType) -> PredictionsError? {
        switch errorType {
        case .accessDenied:
            break
        case .idempotentParameterMismatch:
            break
        case .imageTooLarge:
            break
        case .internalServer:
            break
        case .invalidImageFormat:
            break
        case .invalidPaginationToken:
            break
        case .invalidParameter:
            break
        case .invalidS3Object:
            break
        case .limitExceeded:
            break
        case .provisionedThroughputExceeded:
            break
        case .resourceAlreadyExists:
            break
        case .resourceInUse:
            break
        case .resourceNotFound:
            break
        case .throttling:
            break
        case .unknown:
            break
        case .videoTooLarge:
            break
        @unknown default:
            break
        }

        return nil
    }

    static func map(_ errorType: AWSTextractErrorType) -> PredictionsError? {
        switch errorType {
        case .accessDenied:
            break
        case .badDocument:
            break
        case .documentTooLarge:
            break
        case .idempotentParameterMismatch:
            break
        case .internalServer:
            break
        case .invalidJobId:
            break
        case .invalidParameter:
            break
        case .invalidS3Object:
            break
        case .limitExceeded:
            break
        case .provisionedThroughputExceeded:
            break
        case .throttling:
            break
        case .unknown:
            break
        case .unsupportedDocument:
            break
        @unknown default:
            break
        }

        return nil
    }

    static func map(_ errorType: AWSPollyErrorType) -> PredictionsError? {
        switch errorType {
        case .engineNotSupported:
            break
        case .invalidLexicon:
            break
        case .invalidNextToken:
            break
        case .invalidS3Bucket:
            break
        case .invalidS3Key:
            break
        case .invalidSampleRate:
            break
        case .invalidSnsTopicArn:
            break
        case .invalidSsml:
            break
        case .invalidTaskId:
            break
        case .languageNotSupported:
            break
        case .lexiconNotFound:
            break
        case .lexiconSizeExceeded:
            break
        case .marksNotSupportedForFormat:
            break
        case .maxLexemeLengthExceeded:
            break
        case .maxLexiconsNumberExceeded:
            break
        case .serviceFailure:
            break
        case .ssmlMarksNotSupportedForTextType:
            break
        case .synthesisTaskNotFound:
            break
        case .textLengthExceeded:
            break
        case .unknown:
            break
        case .unsupportedPlsAlphabet:
            break
        case .unsupportedPlsLanguage:
            break
        @unknown default:
            break
        }

        return nil
    }
}
