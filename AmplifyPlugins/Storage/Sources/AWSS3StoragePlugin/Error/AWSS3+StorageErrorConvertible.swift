//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSS3
import AWSClientRuntime

extension AWSS3.NoSuchBucket: StorageErrorConvertible {
    var storageError: StorageError {
        .service(
            "The specific bucket does not exist",
            "",
            self
        )
    }
}

extension AWSClientRuntime.UnknownAWSHTTPServiceError: StorageErrorConvertible {
    var storageError: StorageError {
        let error: StorageError
        switch httpResponse.statusCode {
        case .unauthorized, .forbidden:
            error = .accessDenied(
                StorageErrorConstants.accessDenied.errorDescription,
                StorageErrorConstants.accessDenied.recoverySuggestion,
                self
            )
        case .notFound:
            error = .keyNotFound(
                StorageError.serviceKey,
                "Received HTTP Response status code 404 NotFound",
                "Make sure the key exists before trying to download it.",
                self
            )
        default:
            error = .unknown(
                """
                Unknown service error occured with:
                - status: \(httpResponse.statusCode)
                - message: \(message ?? "")
                """,
                self
            )
        }
        return error
    }
}
