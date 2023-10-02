//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSRekognition
import Amplify
import ClientRuntime


extension AWSRekognition.HumanLoopQuotaExceededException: PredictionsErrorConvertible {
    var predictionsError: PredictionsError {
        .service(
            .init(
                description: "The number of in-progress human reviews you have has exceeded the number allowed.",
                recoverySuggestion: "Try again later.",
                httpStatusCode: httpResponse.statusCode.rawValue,
                underlyingError: self
            )
        )
    }
}

extension AWSRekognition.ResourceNotFoundException: PredictionsErrorConvertible {
    var predictionsError: PredictionsError {
        .service(.resourceNotFound)
    }
}

extension AWSRekognition.ThrottlingException: PredictionsErrorConvertible {
    var predictionsError: PredictionsError {
        .service(.throttling)
    }
}

extension AWSRekognition.InternalServerError: PredictionsErrorConvertible {
    var predictionsError: PredictionsError {
        .service(.internalServerError)
    }
}

extension AWSRekognition.AccessDeniedException: PredictionsErrorConvertible {
    var predictionsError: PredictionsError {
        .service(.accessDenied)
    }
}

extension AWSRekognition.ImageTooLargeException: PredictionsErrorConvertible {
    var predictionsError: PredictionsError {
        .service(
            .init(
                description: "The image you sent was too large.",
                recoverySuggestion: "Try downsizing the image and sending it again.",
                httpStatusCode: httpResponse.statusCode.rawValue,
                underlyingError: self
            )
        )
    }
}

extension AWSRekognition.InvalidImageFormatException: PredictionsErrorConvertible {
    var predictionsError: PredictionsError {
        .service(
            .init(
                description: "The provided image format isn't supported.",
                recoverySuggestion: "Use a supported image format (.JPEG and .PNG) and try again.",
                httpStatusCode: httpResponse.statusCode.rawValue,
                underlyingError: self
            )
        )
    }
}

extension AWSRekognition.InvalidParameterException: PredictionsErrorConvertible {
    var predictionsError: PredictionsError {
        .service(
            .init(
                description: "An input parameter violated a constraint.",
                recoverySuggestion: "Validate your parameters before calling the API operation again.",
                httpStatusCode: httpResponse.statusCode.rawValue,
                underlyingError: self
            )
        )
    }
}

extension AWSRekognition.InvalidS3ObjectException: PredictionsErrorConvertible {
    var predictionsError: PredictionsError {
        .service(
            .init(
                description: "The number of requests exceeded your throughput limit.",
                recoverySuggestion: """
                Decrease the number of calls you are making until it is below the limit for your region.
                Check the limits here:
                https://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html#limits_rekognition
                """,
                httpStatusCode: httpResponse.statusCode.rawValue,
                underlyingError: self
            )
        )
    }
}

extension AWSRekognition.ProvisionedThroughputExceededException: PredictionsErrorConvertible {
    var predictionsError: PredictionsError {
        .service(
            .init(
                description: "The number of requests exceeded your throughput limit.",
                recoverySuggestion: """
                Decrease the number of calls you are making until it is below the limit for your region.
                Check the limits here:
                https://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html#limits_rekognition
                """,
                httpStatusCode: httpResponse.statusCode.rawValue,
                underlyingError: self
            )
        )
    }
}
