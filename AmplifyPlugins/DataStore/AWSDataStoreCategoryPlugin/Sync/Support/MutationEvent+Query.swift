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
        let predicate = fields.modelId == modelId && (fields.inProcess == false || fields.inProcess == nil)

        storageAdapter.query(MutationEvent.self,
                             predicate: predicate,
                             sort: .ascending(fields.createdAt),
                             paginationInput: nil) { completion($0) }
    }
}
