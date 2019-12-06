//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Combine

@available(iOS 13.0, *)
protocol IncomingSubscriptionEventPublisher {
    var publisher: AnyPublisher<MutationSync<AnyModel>, DataStoreError> { get }
}
