//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Event for subscription
public enum SubscriptionEvent<R> {
    /// Connect based event, the associated string will have connection message.
    case connection(SubscriptionConnectionState)

    /// Data event, the associated data contains the data received.
    case data(R)

    /// Failure event, the associated error object contains the error occured.
    case failed(Error)

}
