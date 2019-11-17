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
import AWSTranslate
import AWSComprehend

class PredictionsErrorHelper {

    static func mapHttpResponseCode(statusCode: Int, serviceKey: String) -> PredictionsError? {
        if statusCode >= 200 && statusCode <= 299 {
            return nil
        }

        if statusCode == 404 {
           return PredictionsError.httpStatusError(404, "Please check your request and try again")
        }
        // TODO status error mapper
        return PredictionsError.httpStatusError(statusCode, "TODO some status code to recovery message mapper")
    }
   // swiftlint:disable cyclomatic_complexity
    static func mapPredictionsServiceError(_ error: NSError) -> PredictionsError {
        let defaultError = PredictionsErrorHelper.getDefaultError(error)

        switch error.domain {
        case AWSServiceErrorDomain:
            let errorTypeOptional = AWSServiceErrorType.init(rawValue: error.code)
            guard let errorType = errorTypeOptional else {
                return defaultError
            }
            return PredictionsErrorHelper.map(errorType) ?? defaultError
        case AWSRekognitionErrorDomain:
            guard let errorType = AWSRekognitionErrorType.init(rawValue: error.code) else {
                return defaultError
            }
            return AWSRekognitionErrorMessage.map(errorType) ?? defaultError
        case AWSPollyErrorDomain:
            guard let errorType = AWSPollyErrorType.init(rawValue: error.code) else {
                return defaultError
            }
            return AWSPollyErrorMessage.map(errorType) ?? defaultError
        case AWSTextractErrorDomain:
            guard let errorType = AWSTextractErrorType.init(rawValue: error.code) else {
                return defaultError
            }
            return AWSTextractErrorMessage.map(errorType) ?? defaultError
        case AWSComprehendErrorDomain:
            guard let errorType = AWSComprehendErrorType.init(rawValue: error.code) else {
                return defaultError
            }
            return AWSComprehendErrorMessage.map(errorType) ?? defaultError
        case AWSTranslateErrorDomain:
            guard let errorType = AWSTranslateErrorType.init(rawValue: error.code) else {
                return defaultError
            }
            return AWSTranslateErrorMessage.map(errorType) ?? defaultError
        default:
            return defaultError
        }
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
            return PredictionsError.accessDenied(AWSComprehendErrorMessage.accessDenied.errorDescription,
                                                 AWSComprehendErrorMessage.accessDenied.recoverySuggestion)
        case .unrecognizedClientException:
            break
        case .incompleteSignature:
            break
        case .invalidClientTokenId:
            break
        case .missingAuthenticationToken:
            break
        case .accessDenied:
            return PredictionsError.accessDenied(AWSComprehendErrorMessage.accessDenied.errorDescription,
                                                 AWSComprehendErrorMessage.accessDenied.recoverySuggestion)
        case .expiredToken:
            break
        case .invalidAccessKeyId:
            break
        case .invalidToken:
            break
        case .tokenRefreshRequired:
            break
        case .accessFailure:
            return PredictionsError.accessDenied(AWSComprehendErrorMessage.accessDenied.errorDescription,
                                                 AWSComprehendErrorMessage.accessDenied.recoverySuggestion)
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
}
