//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

final class MutationEventClearState {

    let storageAdapter: StorageEngineAdapter
    init(storageAdapter: StorageEngineAdapter) {
        self.storageAdapter = storageAdapter
    }

    func clearStateOutgoingMutations(completion: @escaping BasicClosure) {
        let fields = MutationEvent.keys
        let predicate = fields.inProcess == true
        let sort = QuerySortDescriptor(fieldName: fields.createdAt.stringValue, order: .ascending)
        let result = storageAdapter.query(
            MutationEvent.self,
            modelSchema: MutationEvent.schema,
            condition: predicate,
            sort: [sort],
            paginationInput: nil,
            eagerLoad: true
        )

        switch result {
        case .failure(let dataStoreError):
            log.error("Failed on clearStateOutgoingMutations: \(dataStoreError)")
        case .success(let mutationEvents):
            updateMutationsState(mutationEvents: mutationEvents, completion: completion)
        }
    }

    private func updateMutationsState(mutationEvents: [MutationEvent], completion: @escaping BasicClosure) {
        for mutationEvent in mutationEvents {
            var inProcessEvent = mutationEvent
            inProcessEvent.inProcess = false

            let result = storageAdapter.save(inProcessEvent, modelSchema: inProcessEvent.schema, condition: nil, eagerLoad: true)
            if case .failure(let error) = result {
                self.log.error("Failed to update mutationEvent:\(error)")
            }
        }
        completion()
    }

}

extension MutationEventClearState: DefaultLogger { }
