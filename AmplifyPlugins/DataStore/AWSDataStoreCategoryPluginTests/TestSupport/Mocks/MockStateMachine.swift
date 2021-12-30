//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
@testable import AWSDataStorePlugin

class MockStateMachine<S, A>: StateMachine<S, A> {
    typealias ExpectActionCriteria = (_ action: A) -> Void
    var expectActionCriteriaQueue: AtomicValue<[ExpectActionCriteria]>

    override init(initialState: S, resolver: @escaping Reducer) {
        self.expectActionCriteriaQueue = AtomicValue(initialValue: [])
        super.init(initialState: initialState, resolver: resolver)
    }
    override func notify(action: A) {
        if let expectActionCriteria = expectActionCriteriaQueue.get().first {
            expectActionCriteria(action)
            expectActionCriteriaQueue.with { $0.removeFirst(1) }
        }
    }
    func pushExpectActionCriteria(expectActionCriteria: @escaping ExpectActionCriteria) {
        expectActionCriteriaQueue.append(expectActionCriteria)
    }
}
