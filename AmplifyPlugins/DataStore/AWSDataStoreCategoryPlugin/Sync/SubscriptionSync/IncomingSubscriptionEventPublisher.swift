//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Combine

enum IncomingSubscriptionEventPublisherEvent {
    case connectionConnected
    case mutationEvent(MutationSync<AnyModel>)
}

@available(iOS 13.0, *)
protocol IncomingSubscriptionEventPublisher: AmplifyCancellable {
    var publisher: AnyPublisher<IncomingSubscriptionEventPublisherEvent, DataStoreError> { get }
}
