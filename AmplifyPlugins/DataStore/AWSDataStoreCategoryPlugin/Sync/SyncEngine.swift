//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine
import Foundation

typealias MutationFuture = Future<MutationEvent, DataStoreError>

class SyncEngine {

    let api: APICategoryGraphQLBehavior
    let mutationQueue: MutationQueue

    init(api: APICategoryGraphQLBehavior = Amplify.API,
         mutationQueue: MutationQueue) {
        self.api = api
        self.mutationQueue = mutationQueue
    }

    func start() {
        // TODO revisit thread strategy (not only here)
        _ = mutationQueue.observe()
            .subscribe(on: DispatchQueue.global(qos: .background))
            .filter { $0.source != .syncEngine }
            .sink(
                receiveCompletion: {
                    print("Queue exhausted! (bring it some fruits and water)")
                    print($0)
                }, receiveValue: { event in
                    // TODO handle result
                    _ = self.submit(event: event)
                }
            )
    }

    func submit(event: MutationEvent) -> MutationFuture {
        // TODO how to get the API name?
        let apiName = ""
        let type = modelType(from: event.modelName)
        return MutationFuture { future in
//            _ = self.api.mutate(apiName: apiName,
//                                document: "",
//                                variables: nil,
//                                responseType: type) {
//                switch $0 {
//                case .unknown:
//                    print("")
//                case .notInProcess:
//                    print("")
//                case .inProcess:
//                    print("")
//                case .completed:
//                    future(.success(event))
//                case .failed(let error):
//                    future(.failure(.invalidOperation(causedBy: error)))
//                }
//            }
        }
    }
}
