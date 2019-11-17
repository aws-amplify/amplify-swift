//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSTextract
import Amplify

typealias AWSTextractErrorString = (errorDescription: ErrorDescription, recoverySuggestion: RecoverySuggestion)

struct AWSTextractErrorMessage {
    static let accessDenied: AWSTextractErrorString = (
        "Access denied!",
        "Please check that your Cognito IAM role has permissions to access Textract.")

    // swiftlint:disable cyclomatic_complexity
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
             return PredictionsError.internalServiceError("", "")
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
