//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine

@available(iOS 13.0, *)

// TODO: Should this be a multicast publisher?
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
}
