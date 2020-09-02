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

    /// Dispatched when network status has changed (active or not)
    /// The HubPayload will be a boolean value `isActive` indicating the status of network
    // TODO: networkStatusChanged to be implemented
    static let networkStatusChanged = "DataStore.networkStatusChanged"

    /// Dispatched on DataStore start and also every time a local mutation is enqueued in the outbox
    /// The HubPayload will be a boolean value `isEmpty` to notify if there are mutations in the outbox
    static let outboxStatus = "DataStore.outboxStatus"

    /// Dispatched when all the graphql subscriptions estabilished
    static let subscriptionEstablished = "DataStore.subscriptionEstablished"

    /// Dispatched when DataStore is about to start sync queries
    /// The HubPayload will be the `name` of each model
    static let syncQueriesStarted = "DataStore.syncQueriesStarted"

    /// Dispatched once for each model when the model instances has been synced (the syncQuery pagination is done)
    /// `ModelSyncedResult` will be the HubPayload which contains `ModelName`, `isFullSync`,
    /// `isDeltaSync` and the count for each `MutationType` (create, update, delete)
    // TODO: modelSynced to be implemented
    static let modelSynced = "DataStore.modelSynced"

    /// Dispatched when all model instances have been synced
    // TODO: syncQueriesReady to be implemented
    static let syncQueriesReady = "DataStore.syncQueriesReady"

    /// Dispatched when DataStore is ready
    // TODO: ready to be implemented
    static let ready = "DataStore.ready"

    /// Dispatched when a local mutation is enqueued in the outbox
    /// The HubPayload will be a `MutationEvent` instance about to send to remote API.
    static let outboxMutationEnqueued = "DataStore.outboxMutationEnqueued"

    /// Dispatched when a mutation in the outbox is sent to backend successfully and has been merged locally
    /// The HubPayload will be a `MutationEvent` instance containing the newly mutated data from the remote API.
    static let outboxMutationProcessed = "DataStore.outboxMutationProcessed"
}
