//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSCore

typealias AWSServiceErrorMessageString = (errorDescription: ErrorDescription, recoverySuggestion: RecoverySuggestion)

struct AWSServiceErrorMessage {
    static let accessDenied: AWSServiceErrorMessageString = (
        "Access denied!",
        "Please check that your Cognito IAM role has permissions to access this service and check to make sure the user is authenticated properly.")
    
    static let resourceNotFound: AWSServiceErrorMessageString = (
        "The specified resource doesn't exist.",
        "Please make sure you either created the resource using the Amplify CLI or the AWS Console")
    
    static let limitExceeded: AWSServiceErrorMessageString = (
        "The number of requests made has exceeded the limit.",
        "Please decrease the number of requests and try again.")
    
    static let throttling: AWSServiceErrorMessageString = (
        "Your rate of request increase is too fast.",
        "Slow down your request rate and gradually increase it.")
    
    static let resourceUnavailable: AWSServiceErrorMessageString = (
        "The resource is currently unavailable.",
        "Please check to see if there is an outage at https://status.aws.amazon.com/ and reach out to AWS support.")
    
    // swiftlint:disable cyclomatic_complexity
    static func map(_ errorType: AWSServiceErrorType) -> PredictionsError? {
        switch errorType {
        case .unknown:
            return PredictionsError.unknownError("", "")
        case .accessDeniedException,
             .accessDenied,
             .accessFailure,
             .authFailure,
             .missingAuthenticationToken,
             .authMissingFailure:
            return PredictionsError.accessDenied(
                AWSServiceErrorMessage.accessDenied.errorDescription,
                AWSServiceErrorMessage.accessDenied.recoverySuggestion)
        case .unrecognizedClientException:
            return PredictionsError.unknownError("There was an unrecognized client exception", "")
        case .throttling,
             .throttlingException:
            return PredictionsError.accessDenied(
            AWSServiceErrorMessage.throttling.errorDescription,
            AWSServiceErrorMessage.throttling.recoverySuggestion)
        default:
            return nil
        }

        return nil
    }
}
