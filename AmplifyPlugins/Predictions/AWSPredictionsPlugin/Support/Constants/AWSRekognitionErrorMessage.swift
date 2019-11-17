//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSRekognition
import Amplify

typealias AWSRekognitionErrorMessageString = (ErrorDescription, RecoverySuggestion)

struct AWSRekognitionErrorMessage {
    static let accessDenied: AWSComprehendErrorString = (
        "Access denied!",
        "Please check that your Cognito IAM role has permissions to access Rekognition.")

    static func map(_ errorType: AWSRekognitionErrorType) -> PredictionsError? {
        switch errorType {
        case .accessDenied:
            return PredictionsError.accessDenied(
                accessDenied.errorDescription,
                accessDenied.recoverySuggestion)
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
}
