//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension MutationEvent {
    static func pendingMutationEvents(forModelId modelId: Model.Identifier,
                                      storageAdapter: StorageEngineAdapter,
                                      completion: DataStoreCallback<[MutationEvent]>) {
        let fields = MutationEvent.keys

        // TODO remove this in favor of a proper sorting API
        // Get mutation events in order of ascending creation date
        let orderByCreatedAt = "ORDER BY \(fields.createdAt.stringValue) ASC"

        let predicate = fields.modelId == modelId && (fields.inProcess == false || fields.inProcess == nil)

        storageAdapter.query(MutationEvent.self,
                             predicate: predicate,
                             paginationInput: nil,
                             additionalStatements: orderByCreatedAt) { completion($0) }
    }
}
