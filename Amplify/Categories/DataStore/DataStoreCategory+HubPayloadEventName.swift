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

    /// Dispatched when network status has changed (active or not)
    /// The HubPayload will be a boolean value `isActive` indicating the status of network
    // TODO: networkStatusChanged to be implemented
    static let networkStatusChanged = "DataStore.networkStatusChanged"

    /// Dispatched on DataStore start and also every time a local mutation is enqueued and processed in the outbox
    /// HubPayload `OutboxStatusEvent` contains a boolean value `isEmpty` to notify if there are mutations in the outbox
    static let outboxStatus = "DataStore.outboxStatus"

    /// Dispatched when all the graphql subscriptions estabilished
    static let subscriptionEstablished = "DataStore.subscriptionEstablished"

    /// Dispatched when DataStore is about to start sync queries
    /// HubPayload `syncQueriesStartedEvent` contains an array of each model's `name`
    static let syncQueriesStarted = "DataStore.syncQueriesStarted"

    /// Dispatched once for each model when the model instances has been synced and updated locally
    /// `ModelSyncedEvent` will be the HubPayload which contains `ModelName`, `isFullSync`,
    /// `isDeltaSync` and the count for each `MutationType` (create, update, delete)
    // TODO: modelSynced to be implemented
    static let modelSynced = "DataStore.modelSynced"

    /// Dispatched when all model instances have been synced
    // TODO: syncQueriesReady to be implemented
    static let syncQueriesReady = "DataStore.syncQueriesReady"

    /// Dispatched when DataStore is ready, at this point all data is available
    // TODO: ready to be implemented
    static let ready = "DataStore.ready"

    /// Dispatched when a local mutation is enqueued in the outbox
    /// The HubPayload will be a `MutationEvent` instance about to send to remote API.
    static let outboxMutationEnqueued = "DataStore.outboxMutationEnqueued"

    /// Dispatched when a mutation in the outbox is sent to backend successfully and has been merged locally
    /// The HubPayload will be a `MutationEvent` instance containing the newly mutated data from the remote API.
    static let outboxMutationProcessed = "DataStore.outboxMutationProcessed"
}
