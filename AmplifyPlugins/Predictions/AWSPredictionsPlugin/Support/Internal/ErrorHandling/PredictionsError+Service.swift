//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension PredictionsError {
    static func unexpectedServiceErrorType(_ underlyingError: Error?) -> Self {
        .service(
            .init(
                description: "An unknown error type was thrown by the service.",
                recoverySuggestion: """
                This should never happen. There is a possibility that there is a bug if this error persists.
                Please take a look at https://github.com/aws-amplify/amplify-ios/issues to see if there are any
                existing issues that match your scenario, and file an issue with the details of the bug if there isn't.
                """,
                underlyingError: underlyingError
            )
        )
    }

    static func unknownServiceError(_ underlyingError: Error?) -> Self {
        .service(
            .init(
                description: "An unknown service error occurred",
                recoverySuggestion: "",
                underlyingError: underlyingError
            )
        )
    }
}
