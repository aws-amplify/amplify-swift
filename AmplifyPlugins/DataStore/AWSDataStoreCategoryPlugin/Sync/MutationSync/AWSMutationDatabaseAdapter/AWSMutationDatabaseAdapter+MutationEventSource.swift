//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine

@available(iOS 13.0, *)
extension AWSMutationDatabaseAdapter: MutationEventSource {
    func getNextMutationEvent(completion: @escaping DataStoreCallback<MutationEvent>) {
        log.verbose(#function)

        guard let storageAdapter = storageAdapter else {
            completion(.failure(DataStoreError.nilStorageAdapter()))
            return
        }

        let fields = MutationEvent.keys
        let predicate = fields.inProcess == false || fields.inProcess == nil
        let sort = QuerySortDescriptor(fieldName: MutationEvent.keys.createdAt.stringValue, order: .ascending)
        storageAdapter.query(MutationEvent.self,
                             predicate: predicate,
                             sort: [sort],
                             paginationInput: nil) { result in
                                switch result {
                                case .failure(let dataStoreError):
                                    completion(.failure(dataStoreError))
                                case .success(let mutationEvents):
                                    guard let notInProcessEvent = mutationEvents.first else {
                                        self.nextEventPromise.set(completion)
                                        return
                                    }
                                    self.markInProcess(mutationEvent: notInProcessEvent,
                                                       storageAdapter: storageAdapter,
                                                       completion: completion)
                                }

        }
    }

    func markInProcess(mutationEvent: MutationEvent,
                       storageAdapter: StorageEngineAdapter,
                       completion: @escaping DataStoreCallback<MutationEvent>) {
        var inProcessEvent = mutationEvent
        inProcessEvent.inProcess = true
        storageAdapter.save(inProcessEvent, condition: nil, completion: completion)
    }

}
