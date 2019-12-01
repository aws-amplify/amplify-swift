//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine

protocol MutationEventSource: class {
    /// Gets the next available mutation event, marking it as "inProcess" before delivery
    func getNextMutationEvent(completion: @escaping DataStoreCallback<MutationEvent>)
}

@available(iOS 13.0, *)
extension AWSMutationDatabaseAdapter: MutationEventSource {
    func getNextMutationEvent(completion: @escaping DataStoreCallback<MutationEvent>) {
        log.verbose(#function)

        guard let storageAdapter = storageAdapter else {
            let dataStoreError = DataStoreError.configuration(
                "storageAdapter is unexpectedly nil in an internal operation",
                """
                The reference to storageAdapter has been released while an ongoing mutation was being processed.
                """
            )
            completion(.failure(dataStoreError))
            return
        }

        let fields = MutationEvent.keys
        let predicateFactory: QueryPredicateFactory = {
            fields.inProcess.ne(nil).or(fields.inProcess.eq(false))
        }

        let orderAndLimitClause = """
        ORDER BY \(MutationEvent.keys.createdAt.stringValue) ASC
        LIMIT 1
        """

        storageAdapter.query(MutationEvent.self,
                             predicate: predicateFactory(),
                             additionalStatements: orderAndLimitClause) { result in
                                switch result {
                                case .failure(let dataStoreError):
                                    completion(.failure(dataStoreError))
                                case .success(let mutationEvents):
                                    guard let notInProcessEvent = mutationEvents.first else {
                                        self.nextEventPromise = completion
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
        storageAdapter.save(inProcessEvent, completion: completion)
    }

}
