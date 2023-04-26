//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
//import AWSCore

typealias AWSServiceErrorMessageString = (errorDescription: ErrorDescription, recoverySuggestion: RecoverySuggestion)

struct AWSServiceErrorMessage {
    static let accessDenied: AWSServiceErrorMessageString = (
        "Access denied",
        """
        Please check that your Cognito IAM role has permissions to access this service and check to make sure the user
        is authenticated properly.
        """
    )

    static let resourceNotFound: AWSServiceErrorMessageString = (
        "The specified resource doesn't exist.",
        "Please make sure you either created the resource using the Amplify CLI or the AWS Console"
    )

    static let limitExceeded: AWSServiceErrorMessageString = (
        "The number of requests made has exceeded the limit.",
        "Please decrease the number of requests and try again."
    )

    static let throttling: AWSServiceErrorMessageString = (
        "Your rate of request increase is too fast.",
        "Slow down your request rate and gradually increase it."
    )

    static let resourceUnavailable: AWSServiceErrorMessageString = (
        "The resource is currently unavailable.",
        "Please check to see if there is an outage at https://status.aws.amazon.com/ and reach out to AWS support."
    )

    static let internalServerError: AWSServiceErrorMessageString = (
        "An internal server error occurred.",
        """
        This should never happen. There is a possibility that there is a bug if this error persists.
        Please take a look at https://github.com/aws-amplify/amplify-ios/issues to see if there are any
        existing issues that match your scenario, and file an issue with the details of the bug if there isn't.
        """
    )

    static func map(_ errorType: AWSServiceErrorType) -> PredictionsError? {
        switch errorType {
        case .unknown:
            return PredictionsError.unknown("", "")
        case .accessDeniedException,
             .accessDenied,
             .accessFailure,
             .authFailure,
             .missingAuthenticationToken,
             .authMissingFailure:
            return PredictionsError.accessDenied(
                AWSServiceErrorMessage.accessDenied.errorDescription,
                AWSServiceErrorMessage.accessDenied.recoverySuggestion
            )
        case .unrecognizedClientException:
            return PredictionsError.unknown("There was an unrecognized client exception", "")
        case .throttling,
             .throttlingException:
            return PredictionsError.accessDenied(
                AWSServiceErrorMessage.throttling.errorDescription,
                AWSServiceErrorMessage.throttling.recoverySuggestion
            )
        }
    }
}

// TODO: This is a temporary shadow type - replace it with the correct type
enum AWSServiceErrorType {
    case unknown
    case accessDeniedException
    case accessDenied
    case accessFailure
    case authFailure
    case missingAuthenticationToken
    case authMissingFailure
    case unrecognizedClientException
    case throttling
    case throttlingException
}
