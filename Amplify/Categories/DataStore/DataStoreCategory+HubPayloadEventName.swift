//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public extension HubPayload.EventName {
    struct DataStore { }
}

public extension HubPayload.EventName.DataStore {
    /// Dispatched when DataStore begins syncing to the API
    static let syncStarted = "DataStore.syncStarted"

    /// Dispatched when DataStore receives a sync response from a locally-sourced mutation. The HubPayload will be an
    /// `AnyModel` instance containing the newly mutated data from the service.
    static let mutationSyncReceived = "DataStore.mutationSyncReceived"

    /// Dispatched when DataStore receives a subscription message from the API
    static let subscriptionReceived = "DataStore.subscriptionReceived"
}
