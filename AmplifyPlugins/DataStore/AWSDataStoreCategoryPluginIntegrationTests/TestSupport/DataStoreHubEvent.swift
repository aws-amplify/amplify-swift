//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSDataStorePlugin

/// Initialize with `HubPayload`'s `eventName: String` and `data: Any?` fields to return an enum of events with their
/// expected payloads in their respective types
enum DataStoreHubEvent {
    case syncStarted
    case syncReceived(MutationEvent)
    case conditionalSaveFailed
    case outboxStatus(OutboxStatusEvent)
    case subscriptionsEstablished
    case syncQueriesStarted(SyncQueriesStartedEvent)
    case modelSynced(ModelSyncedEvent)
    case syncQueriesReady
    case ready
    case networkStatus(NetworkStatusEvent)
    case outboxMutationEnqueued(OutboxMutationEvent)
    case outboxMutationProcessed(OutboxMutationEvent)
    case unknown(HubPayload)

    init(payload: HubPayload) {
        switch payload.eventName {
        case HubPayload.EventName.DataStore.syncStarted:
            Amplify.DataStore.log.verbose("DataStoreEvent: SyncStarted")
            self = .syncStarted
        case HubPayload.EventName.DataStore.syncReceived:
            guard let mutationEvent = payload.data as? MutationEvent else {
                fatalError("Expected data object not found")
            }
            self = .syncReceived(mutationEvent)
        case HubPayload.EventName.DataStore.conditionalSaveFailed:
            Amplify.DataStore.log.verbose("DataStoreEvent: Conditional Save Failed")
            self = .conditionalSaveFailed
        case HubPayload.EventName.DataStore.outboxStatus:
            guard let outboxStatusEvent = payload.data as? OutboxStatusEvent else {
                fatalError("Expected data object not found")
            }
            Amplify.DataStore.log.verbose("DataStoreEvent: OutboxStatus isEmpty: \(outboxStatusEvent.isEmpty)")
            self = .outboxStatus(outboxStatusEvent)
        case HubPayload.EventName.DataStore.subscriptionsEstablished:
            Amplify.DataStore.log.verbose("DataStoreEvent: Subscriptions Established")
            self = .subscriptionsEstablished
        case HubPayload.EventName.DataStore.syncQueriesStarted:
            guard let syncQueriesStartedEvent = payload.data as? SyncQueriesStartedEvent else {
                fatalError("Expected data object not found")
            }
            Amplify.DataStore.log.verbose("DataStoreEvent: SyncQueriesStarted \(syncQueriesStartedEvent)")
            self = .syncQueriesStarted(syncQueriesStartedEvent)
        case HubPayload.EventName.DataStore.modelSynced:
            guard let modelSyncedEvent = payload.data as? ModelSyncedEvent else {
                fatalError("Expected data object not found")
            }
            Amplify.DataStore.log.verbose("DataStoreEvent: ModelSynced: \(modelSyncedEvent)")
            self = .modelSynced(modelSyncedEvent)
        case HubPayload.EventName.DataStore.syncQueriesReady:
            Amplify.DataStore.log.verbose("DataStoreEvent: SyncQueriesReady")
            self = .syncQueriesReady
        case HubPayload.EventName.DataStore.ready:
            Amplify.DataStore.log.verbose("DataStoreEvent: Ready")
            self = .ready
        case HubPayload.EventName.DataStore.networkStatus:
            guard let networkStatusEvent = payload.data as? NetworkStatusEvent else {
                fatalError("Expected data object not found")
            }
            Amplify.DataStore.log.verbose("DataStoreEvent: NetworkStatus: \(networkStatusEvent)")
            self = .networkStatus(networkStatusEvent)
        case HubPayload.EventName.DataStore.outboxMutationEnqueued:
            guard let outboxMutationEvent = payload.data as? OutboxMutationEvent else {
                fatalError("Expected data object not found")
            }
            Amplify.DataStore.log.verbose("DataStoreEvent: OutboxMutationEnqueued \(outboxMutationEvent.modelName)")
            self = .outboxMutationEnqueued(outboxMutationEvent)
        case HubPayload.EventName.DataStore.outboxMutationProcessed:
            guard let outboxMutationEvent = payload.data as? OutboxMutationEvent else {
                fatalError("Expected data object not found")
            }
            Amplify.DataStore.log.verbose("DataStoreEvent: OutboxMutationProcessed \(outboxMutationEvent.modelName)")
            self = .outboxMutationProcessed(outboxMutationEvent)
        default:
            Amplify.DataStore.log.verbose("DataStoreEvent: Unknown: \(payload)")
            self = .unknown(payload)
        }
    }
}
