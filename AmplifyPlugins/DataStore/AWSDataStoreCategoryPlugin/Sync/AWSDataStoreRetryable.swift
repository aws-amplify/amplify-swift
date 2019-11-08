//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct AWSDataStoreRetryAdvice {
    let shouldRetry: Bool
    let retryInterval: DispatchTimeInterval?
}

protocol AWSDataStoreRetryable {
    func shouldRetryRequest(for error: AWSDataStoreClientError) -> AWSDataStoreRetryAdvice
    func shouldRetryMutationRequest(for error: Error) -> AWSDataStoreRetryAdvice
}
