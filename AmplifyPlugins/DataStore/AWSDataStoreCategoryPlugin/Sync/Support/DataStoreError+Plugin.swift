//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

/// Convenience error types
extension DataStoreError {

    static func nilStorageAdapter(file: StaticString = #file,
                                  function: StaticString = #function,
                                  line: UInt = #line) -> DataStoreError {
        .configuration(
            "storageAdapter is unexpectedly nil in an internal operation",
            """
            The reference to storageAdapter has been released while an ongoing mutation was being processed. \
            \(file), \(function), \(line)
            """
        )
    }

}
