//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSRekognition
import Amplify

typealias AWSRekognitionErrorMessageString = (
    errorDescription: ErrorDescription,
    recoverySuggestion: RecoverySuggestion)

struct AWSRekognitionErrorMessage {
    static let accessDenied: AWSRekognitionErrorMessageString = (
        "Access denied",
        "Please check that your Cognito IAM role has permissions to access Rekognition.")

    static let imageTooLarge: AWSRekognitionErrorMessageString = (
        "The image you sent was too large.",
        "Try downsizing the image and sending it again.")

    static let invalidImageFormat: AWSRekognitionErrorMessageString = (
        "The provided image format isn't supported.",
        "Use a supported image format (.JPEG and .PNG) and try again.")

    static let invalidParameter: AWSRekognitionErrorMessageString = (
        "An input parameter violated a constraint.",
        "Validate your parameters before calling the API operation again.")

    static let limitExceeded: AWSRekognitionErrorMessageString = (
        "The request exceeded the service limits.",
        """
        Decrease the number of calls you are making or make sure your request is below the service limits for your
        region. Check the limits here:
        https://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html#limits_rekognition
        """)

    static let provisionedThroughputExceeded: AWSRekognitionErrorMessageString = (
        "The number of requests exceeded your throughput limit.",
        """
        Decrease the number of calls you are making until it is below the limit for your region.
        Check the limits here:
        https://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html#limits_rekognition
        """)

    static let resourceInUse: AWSRekognitionErrorMessageString = (
        "The resource is already in use.",
        "Retry when the resource is available.")

    static let imageNotFound: AWSRekognitionErrorMessageString = (
        "Something was wrong with the image file, make sure it exists.",
        "Try choosing an image and sending it again.")

    static let noResultFound: AWSRekognitionErrorMessageString = (
        "No result was found. An unknown error occurred.",
        "Please try again.")

    // swiftlint:disable cyclomatic_complexity
    static func map(_ errorType: AWSRekognitionErrorType) -> PredictionsError? {
        switch errorType {
        case .accessDenied:
            return PredictionsError.accessDenied(
                accessDenied.errorDescription,
                accessDenied.recoverySuggestion)
        case .imageTooLarge:
            return PredictionsError.service(imageTooLarge.errorDescription,
                                            imageTooLarge.recoverySuggestion)
        case .internalServer:
            return PredictionsError.service(AWSServiceErrorMessage.internalServerError.errorDescription,
                                            AWSServiceErrorMessage.internalServerError.recoverySuggestion)
        case .invalidImageFormat:
            return PredictionsError.service(invalidImageFormat.errorDescription,
                                            invalidImageFormat.recoverySuggestion)
        case .invalidParameter:
            return PredictionsError.service(invalidParameter.errorDescription,
                                            invalidParameter.recoverySuggestion)
        case .limitExceeded:
            return PredictionsError.service(limitExceeded.errorDescription,
                                            limitExceeded.recoverySuggestion)
        case .provisionedThroughputExceeded:
            return PredictionsError.service(provisionedThroughputExceeded.errorDescription,
                                            provisionedThroughputExceeded.recoverySuggestion)
        case .resourceInUse:
            return PredictionsError.service(resourceInUse.errorDescription,
                                            resourceInUse.recoverySuggestion)
        case .resourceNotFound:
            return PredictionsError.service(AWSServiceErrorMessage.resourceNotFound.errorDescription,
                                            AWSServiceErrorMessage.resourceNotFound.recoverySuggestion)
        case .throttling:
            return PredictionsError.service(AWSServiceErrorMessage.throttling.errorDescription,
                                            AWSServiceErrorMessage.throttling.recoverySuggestion)
        case .unknown:
            return PredictionsError.unknown("An unknown error occurred.", "")
        case .videoTooLarge:
            return PredictionsError.service(limitExceeded.errorDescription,
                                            limitExceeded.recoverySuggestion)
        default:
            return nil
        }
    }
}
