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

extension AWSS3.NotFound: StorageErrorConvertible {
    var storageError: StorageError {
        .keyNotFound(
            "<TODO serviceKey>",
            "Unable to generate URL for non-existent key: <TODO serviceKey>",
            "Please ensure the key is valid or the object has been uploaded",
            nil
        )
    }

    var fallbackDescription: String {
        ""
    }
}

extension AWSS3.NoSuchBucket: StorageErrorConvertible {
    var storageError: StorageError {
        .service(
            "The specific bucket does not exist",
            "",
            self
        )
    }

    var fallbackDescription: String {
        ""
    }
}

extension AWSClientRuntime.UnknownAWSHTTPServiceError: StorageErrorConvertible {
    var fallbackDescription: String { "" }

    var storageError: StorageError {
        .unknown(
            """
            Unknown service error occured with:
            - status: \(httpResponse.statusCode)
            - message: \(message ?? fallbackDescription)
            """,
            self
        )
    }
}
