//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSTextract
import Amplify
import ClientRuntime


extension AWSTextract.HumanLoopQuotaExceededException: PredictionsErrorConvertible {
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

extension AWSTextract.ThrottlingException: PredictionsErrorConvertible {
    var predictionsError: PredictionsError {
        .service(.throttling)
    }
}

extension AWSTextract.InternalServerError: PredictionsErrorConvertible {
    var predictionsError: PredictionsError {
        .service(.internalServerError)
    }
}

extension AWSTextract.AccessDeniedException: PredictionsErrorConvertible {
    var predictionsError: PredictionsError {
        .service(.accessDenied)
    }
}

extension AWSTextract.InvalidParameterException: PredictionsErrorConvertible {
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

extension AWSTextract.InvalidS3ObjectException: PredictionsErrorConvertible {
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

extension AWSTextract.ProvisionedThroughputExceededException: PredictionsErrorConvertible {
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


extension AWSTextract.BadDocumentException: PredictionsErrorConvertible {
    var predictionsError: PredictionsError {
        .service(
            .init(
                description: "The image sent over was corrupt or malformed.",
                recoverySuggestion: "Please double check the image sent over and try again.",
                httpStatusCode: httpResponse.statusCode.rawValue,
                underlyingError: self
            )
        )
    }
}

extension AWSTextract.DocumentTooLargeException: PredictionsErrorConvertible {
    var predictionsError: PredictionsError {
        .service(
            .init(
                description: "The image sent over was too large.",
                recoverySuggestion: "Please decrease the size of the image sent over and try again.",
                httpStatusCode: httpResponse.statusCode.rawValue,
                underlyingError: self
            )
        )
    }
}


extension AWSTextract.UnsupportedDocumentException: PredictionsErrorConvertible {
    var predictionsError: PredictionsError {
        .service(
            .init(
                description: "The document type sent over is unsupported",
                recoverySuggestion: "The formats supported are PNG or JPEG format.",
                httpStatusCode: httpResponse.statusCode.rawValue,
                underlyingError: self
            )
        )
    }
}
