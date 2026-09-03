//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine

/// Ingests MutationEvents from and writes them to the MutationEvent persistent store
protocol MutationEventIngester: AnyObject {
    // `@Sendable` to match the implementation, which invokes the completion from a `Future`.
    func submit(mutationEvent: MutationEvent, completion: @escaping @Sendable (Result<MutationEvent, DataStoreError>) -> Void)
}
