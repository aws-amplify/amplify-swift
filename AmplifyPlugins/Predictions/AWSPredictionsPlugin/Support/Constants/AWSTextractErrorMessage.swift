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
    
    static let throttling: AWSTextractErrorString = (
        "Your rate of request increase is too fast.",
        "Slow down your request rate and gradually increase it.")
    
    static let limitExceeded: AWSTextractErrorString = (
        "The request exceeded the service limits.",
        """
        Decrease the number of calls you are making or make sure your request is below the service limits for your region.
        Check the limits here:
        https://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html#limits_textract
        """)
    
    static let provisionedThroughputExceeded: AWSTextractErrorString = (
        "The number of requests exceeded your throughput limit.",
        """
        Decrease the number of calls you are making until it is below the limit for your region.
        Check the limits here:
        https://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html#limits_textract
        """)
    
    static let invalidParameter: AWSTextractErrorString = (
        "An input parameter violated a constraint.",
        "Validate your parameters before calling the API operation again.")
    
    static let badDocument: AWSTextractErrorString = (
        "The image sent over was corrupt or malformed.",
        "Please double check the image sent over and try again.")
    
    static let documentTooLarge: AWSTextractErrorString = (
        "The image sent over was too large.",
        "Please decrease the size of the image sent over and try again.")
    
    static let unsupportedDocument: AWSTextractErrorString = (
        "The document type sent over is unsupported",
        "The formats supported are PNG or JPEG format.")
    
    // swiftlint:disable cyclomatic_complexity
    static func map(_ errorType: AWSTextractErrorType) -> PredictionsError? {
        switch errorType {
        case .accessDenied:
            return PredictionsError.accessDenied(
                accessDenied.errorDescription,
                accessDenied.recoverySuggestion)
        case .badDocument:
            return PredictionsError.serviceError(
                badDocument.errorDescription,
                badDocument.recoverySuggestion)
        case .documentTooLarge:
            return PredictionsError.serviceError(
                documentTooLarge.errorDescription,
                documentTooLarge.recoverySuggestion)
        case .internalServer:
            return PredictionsError.internalServiceError("", "")
        case .invalidParameter:
            return PredictionsError.serviceError(
                invalidParameter.errorDescription,
                invalidParameter.recoverySuggestion)
        case .limitExceeded:
            return PredictionsError.serviceError(
                limitExceeded.errorDescription,
                limitExceeded.recoverySuggestion)
        case .provisionedThroughputExceeded:
            return PredictionsError.serviceError(
                provisionedThroughputExceeded.errorDescription,
                provisionedThroughputExceeded.recoverySuggestion)
        case .throttling:
            return PredictionsError.serviceError(
                throttling.errorDescription,
                throttling.recoverySuggestion)
        case .unknown:
            return PredictionsError.unknownError("An unknown error occurred.", "")
        case .unsupportedDocument:
            return PredictionsError.serviceError(
                unsupportedDocument.errorDescription,
                unsupportedDocument.recoverySuggestion)
        default:
            return nil
        }
    }
}
