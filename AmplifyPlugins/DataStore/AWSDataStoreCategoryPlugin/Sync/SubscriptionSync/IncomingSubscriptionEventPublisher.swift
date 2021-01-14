//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Combine

import protocol Amplify.Cancellable // swiftlint:disable:this duplicate_imports

enum IncomingSubscriptionEventPublisherEvent {
    case connectionConnected
    case mutationEvent(MutationSync<AnyModel>)
}

@available(iOS 13.0, *)
protocol IncomingSubscriptionEventPublisher: Cancellable {
    var publisher: AnyPublisher<IncomingSubscriptionEventPublisherEvent, DataStoreError> { get }
}
