//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine

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
            completion(.failure(dataStoreError))
        case .success(let mutationEvents):
            if let notInProcessEvent = mutationEvents.first {
                completion(self.markInProcess(mutationEvent: notInProcessEvent, storageAdapter: storageAdapter))
            } else {
                self.nextEventPromise.set(completion)
            }
        }
    }

    func markInProcess(
        mutationEvent: MutationEvent,
        storageAdapter: StorageEngineAdapter
    ) -> Result<MutationEvent, DataStoreError> {
        var inProcessEvent = mutationEvent
        inProcessEvent.inProcess = true
        return storageAdapter.save(
            inProcessEvent,
            modelSchema: inProcessEvent.schema,
            condition: nil,
            eagerLoad: true
        ).map { $0.0 }
    }

}
