//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Event for subscription
public enum SubscriptionEvent<T> {
    /// Connect based event, the associated string will have connection message.
    case connection(SubscriptionConnectionState)

    /// Data event, the associated data contains the data received.
    case data(T)

    /// Failure event, the associated error object contains the error occured.
    case failed(Error)

}

public enum SubscriptionConnectionState {

     /// The subscription is in process of connecting
    case connecting

    /// The subscription has connected and is receiving events from the service
    case connected

    /// The subscription has been disconnected because of a lifecycle event or manual disconnect request
    case disconnected
}
