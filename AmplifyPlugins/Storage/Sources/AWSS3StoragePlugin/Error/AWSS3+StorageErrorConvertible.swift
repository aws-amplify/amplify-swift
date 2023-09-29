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
        .unknown(
            """
            Unknown service error occured with:
            - status: \(httpResponse.statusCode)
            - message: \(message ?? "")
            """,
            self
        )
    }
}
