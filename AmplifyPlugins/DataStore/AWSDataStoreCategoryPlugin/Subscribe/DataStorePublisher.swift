//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine

// TODO: Should this be a multicast publisher?
@available(iOS 13.0, *)
struct DataStorePublisher: DataStoreSubscribeBehavior {

    private let subject = PassthroughSubject<MutationEvent, DataStoreError>()

    func publisher<M: Model>(for modelType: M.Type) -> AnyPublisher<MutationEvent, DataStoreError> {
        return subject
            .filter { $0.modelName == modelType.modelName }
            .eraseToAnyPublisher()
    }

    func send(input: MutationEvent) {
        subject.send(input)
    }

    func send(dataStoreError: DataStoreError) {
        subject.send(completion: .failure(dataStoreError))
    }

    func sendFinished() {
        subject.send(completion: .finished)
    }
}
