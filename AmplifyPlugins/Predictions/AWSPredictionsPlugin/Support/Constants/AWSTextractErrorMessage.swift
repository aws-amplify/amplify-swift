//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSTextract
import Amplify

typealias AWSTextractErrorString = (ErrorDescription, RecoverySuggestion)

struct AWSTextractErrorMessage {
    static let accessDenied: AWSComprehendErrorString = (
        "Access denied!",
        "Please check that your Cognito IAM role has permissions to access Textract.")

    static func map(_ errorType: AWSTextractErrorType) -> PredictionsError? {
        switch errorType {
        case .accessDenied:
            return PredictionsError.accessDenied(
                accessDenied.errorDescription,
                accessDenied.recoverySuggestion)
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
}
