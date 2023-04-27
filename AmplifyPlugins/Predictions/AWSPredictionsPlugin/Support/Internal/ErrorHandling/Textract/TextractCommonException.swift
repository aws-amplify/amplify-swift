//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSTextract
import Amplify
import ClientRuntime

enum TextractCommonException {
    static func badDocument(_ error: Error, statusCode: HttpStatusCode?) -> PredictionsError  {
        return .service(
            .init(
                description: "The image sent over was corrupt or malformed.",
                recoverySuggestion: "Please double check the image sent over and try again.",
                httpStatusCode: statusCode?.rawValue,
                underlyingError: error
            )
        )
    }

    static func documentTooLarge(_ error: Error, statusCode: HttpStatusCode?) -> PredictionsError  {
        return .service(
            .init(
                description: "The image sent over was too large.",
                recoverySuggestion: "Please decrease the size of the image sent over and try again.",
                httpStatusCode: statusCode?.rawValue,
                underlyingError: error
            )
        )
    }

    static func unsupportedDocument(_ error: Error, statusCode: HttpStatusCode?) -> PredictionsError  {
        return .service(
            .init(
                description: "The document type sent over is unsupported",
                recoverySuggestion: "The formats supported are PNG or JPEG format.",
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
                https://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html#limits_textract
                """,
                httpStatusCode: statusCode?.rawValue,
                underlyingError: error
            )
        )
    }
}
