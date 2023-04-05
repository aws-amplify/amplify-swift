//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSTextract
import Amplify

typealias AWSTextractErrorString = (errorDescription: ErrorDescription, recoverySuggestion: RecoverySuggestion)

struct AWSTextractErrorMessage {
    static let accessDenied: AWSTextractErrorString = (
        "Access denied",
        "Please check that your Cognito IAM role has permissions to access Textract.")

    static let limitExceeded: AWSTextractErrorString = (
        "The request exceeded the service limits.",
        """
        Decrease the number of calls you are making or make sure your request is below the service limits for your
        region. Check the limits here:
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
            return PredictionsError.accessDenied(accessDenied.errorDescription,
                                                 accessDenied.recoverySuggestion)
        case .badDocument:
            return PredictionsError.service(badDocument.errorDescription,
                                                 badDocument.recoverySuggestion)
        case .documentTooLarge:
            return PredictionsError.service(documentTooLarge.errorDescription,
                                                 documentTooLarge.recoverySuggestion)
        case .internalServer:
            return PredictionsError.service(AWSServiceErrorMessage.internalServerError.errorDescription,
                                            AWSServiceErrorMessage.internalServerError.recoverySuggestion)
        case .invalidParameter:
            return PredictionsError.service(invalidParameter.errorDescription,
                                            invalidParameter.recoverySuggestion)
        case .limitExceeded:
            return PredictionsError.service(limitExceeded.errorDescription,
                                            limitExceeded.recoverySuggestion)
        case .provisionedThroughputExceeded:
            return PredictionsError.service(provisionedThroughputExceeded.errorDescription,
                                            provisionedThroughputExceeded.recoverySuggestion)
        case .throttling:
            return PredictionsError.service(AWSServiceErrorMessage.throttling.errorDescription,
                                            AWSServiceErrorMessage.throttling.recoverySuggestion)
        case .unknown:
            return PredictionsError.unknown("An unknown error occurred.", "")
        case .unsupportedDocument:
            return PredictionsError.service(unsupportedDocument.errorDescription,
                                            unsupportedDocument.recoverySuggestion)
        default:
            return nil
        }
    }
}
