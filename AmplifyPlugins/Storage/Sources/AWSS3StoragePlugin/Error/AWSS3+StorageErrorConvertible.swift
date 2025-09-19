//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSS3
import Foundation
@_spi(UnknownAWSHTTPServiceError) import AWSClientRuntime

extension AWSS3.NoSuchBucket: StorageErrorConvertible {
    var storageError: StorageError {
        .service(
            "The specific bucket does not exist",
            "Make sure the bucket exists",
            self
        )
    }
}

extension AWSClientRuntime.UnknownAWSHTTPServiceError: StorageErrorConvertible {
    var storageError: StorageError {
        let error: StorageError = switch httpResponse.statusCode {
        case .unauthorized, .forbidden:
            .accessDenied(
                StorageErrorConstants.accessDenied.errorDescription,
                StorageErrorConstants.accessDenied.recoverySuggestion,
                self
            )
        case .notFound:
            .keyNotFound(
                StorageError.serviceKey,
                "Received HTTP Response status code 404 NotFound",
                "Make sure the key exists before trying to download it.",
                self
            )
        default:
            .unknown(
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
