//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public extension HubPayload.EventName {
    struct DataStore { }
}

public extension HubPayload.EventName.DataStore {
    /// Dispatched when DataStore begins syncing to the remote API via the API category
    static let syncStarted = "DataStore.syncStarted"

    /// Dispatched when DataStore receives a sync response from the remote API via the API category. This event does not
    /// define the source of the event--it could be in response to either a subscription or a locally-sourced mutation.
    /// Regardless of source, incoming sync updates always have the possibility of updating local data, so listeners
    /// who are interested in model updates must be notified in any case of a sync received. The HubPayload will be a
    /// `MutationEvent` instance containing the newly mutated data from the remote API.
    static let syncReceived = "DataStore.syncReceived"

    /// Dispatched when DataStore receives a sync response from the remote API via the API category. The Hub Payload
    /// will be a `MutationEvent` instance that caused the conditional save failed.
    static let conditionalSaveFailed = "DataStore.conditionalSaveFailed"
}
