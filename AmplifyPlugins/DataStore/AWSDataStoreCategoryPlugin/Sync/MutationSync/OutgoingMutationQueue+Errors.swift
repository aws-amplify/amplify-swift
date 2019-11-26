//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension OutgoingMutationQueue {
    struct Errors {
        static let nilStorageAdapter = DataStoreError.configuration(
            "storageAdapter is unexpectedly nil",
            """
            The reference to storageAdapter has been released while an ongoing mutation was being processed.
            There is a possibility that there is a bug if this error persists. Please take a look at
            https://github.com/aws-amplify/amplify-ios/issues to see if there are any existing issues that
            match your scenario, and file an issue with the details of the bug if there isn't.
            """
        )

        static let nilAPIBehavior = DataStoreError.configuration(
            "API is unexpectedly nil",
            """
            The reference to storageAdapter has been released while an ongoing mutation was being processed.
            There is a possibility that there is a bug if this error persists. Please take a look at
            https://github.com/aws-amplify/amplify-ios/issues to see if there are any existing issues that
            match your scenario, and file an issue with the details of the bug if there isn't.
            """
        )
    }
}
