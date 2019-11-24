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
    /// Dispatched when DataStore begins syncing to the cloud via the API category
    static let syncStarted = "DataStore.syncStarted"

    /// Dispatched when DataStore receives a sync response from the cloud via the API category, where the source of the
    /// event was a mutation made in the local app (as opposed to a mutation made by some external party, which would be
    /// represented as a subscription). The HubPayload will be an `AnyModel` instance containing the newly
    /// mutated data from the service.
    static let mutationSyncReceived = "DataStore.mutationSyncReceived"

    /// Dispatched when DataStore receives a subscription message from the cloud via the API category, where the source
    /// of the event was a mutation made by some external party (as opposed to a local `save` operation, which would be
    /// modeled as a mutation sync). The HubPayload will be an `AnyModel` instance containing the newly
    /// mutated data from the service.
    static let subscriptionReceived = "DataStore.subscriptionReceived"
}
