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
        let sort = QuerySortDescriptor(fieldName: fields.createdAt.stringValue, order: .ascending)
        storageAdapter.query(MutationEvent.self,
                             predicate: predicate,
                             sort: [sort],
                             paginationInput: nil) { completion($0) }
    }
}
