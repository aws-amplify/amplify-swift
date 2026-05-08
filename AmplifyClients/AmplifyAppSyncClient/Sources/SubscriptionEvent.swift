//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// Events emitted by a GraphQL subscription stream.
///
/// Lifecycle: the stream emits `.connecting` → `.connected` → `.data(...)` repeatedly,
/// then either completes normally (user cancel, server complete, client close) or
/// throws an error (network, auth, timeout, etc.).
public enum SubscriptionEvent<T: Decodable & Sendable>: Sendable {
    /// A data message received from the subscription.
    case data(GraphQLResponse<T>)
    /// The subscription is being established (WebSocket connecting + registration in progress).
    case connecting
    /// The subscription is established and receiving data.
    case connected
}
