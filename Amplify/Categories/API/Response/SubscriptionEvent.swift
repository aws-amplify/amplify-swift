//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Event for subscription
public enum SubscriptionEvent<T> {
    /// The subscription's connection state has changed.
    case connection(SubscriptionConnectionState)

    /// The subscription received data.
    case data(T)

    // TODO: do we really need this? https://github.com/aws-amplify/amplify-ios/pull/79/files#r344769874
    /// The subscription received an error.
    case failed(Error)

}
