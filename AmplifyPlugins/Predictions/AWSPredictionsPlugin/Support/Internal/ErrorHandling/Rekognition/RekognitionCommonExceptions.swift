//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSRekognition
import Amplify
import ClientRuntime

enum RekognitionCommonExceptions {
    static func imageTooLarge(_ error: Error, statusCode:  HttpStatusCode?) -> PredictionsError  {
        return .service(
            .init(
                description: "The image you sent was too large.",
                recoverySuggestion: "Try downsizing the image and sending it again.",
                httpStatusCode: statusCode?.rawValue,
                underlyingError: error
            )
        )
    }

    static func invalidImageFormat(_ error: Error, statusCode:  HttpStatusCode?) -> PredictionsError  {
        return .service(
            .init(
                description: "The provided image format isn't supported.",
                recoverySuggestion: "Use a supported image format (.JPEG and .PNG) and try again.",
                httpStatusCode: statusCode?.rawValue,
                underlyingError: error
            )
        )
    }

    static func invalidParameter(_ error: Error, statusCode:  HttpStatusCode?) -> PredictionsError  {
        return .service(
            .init(
                description: "An input parameter violated a constraint.",
                recoverySuggestion: "Validate your parameters before calling the API operation again.",
                httpStatusCode: statusCode?.rawValue,
                underlyingError: error
            )
        )
    }

    static func invalidS3Object(_ error: Error, statusCode:  HttpStatusCode?) -> PredictionsError  {
        .service(
            .init(
                description: "The number of requests exceeded your throughput limit.",
                recoverySuggestion: """
                Decrease the number of calls you are making until it is below the limit for your region.
                Check the limits here:
                https://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html#limits_rekognition
                """,
                httpStatusCode: statusCode?.rawValue,
                underlyingError: error
            )
        )
    }

    static func provisionedThroughputExceeded(_ error: Error, statusCode:  HttpStatusCode?) -> PredictionsError  {
        .service(
            .init(
                description: "The number of requests exceeded your throughput limit.",
                recoverySuggestion: """
                Decrease the number of calls you are making until it is below the limit for your region.
                Check the limits here:
                https://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html#limits_rekognition
                """,
                httpStatusCode: statusCode?.rawValue,
                underlyingError: error
            )
        )
    }
}
