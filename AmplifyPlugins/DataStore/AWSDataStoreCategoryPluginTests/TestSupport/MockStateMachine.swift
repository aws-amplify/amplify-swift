//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import AWSDataStoreCategoryPlugin

class MockStateMachine<S, A>: StateMachine<S, A> {
    typealias ExpectActionCriteria = (_ action: A) -> Void
    var expectActionCriteriaQueue: [ExpectActionCriteria]

    override init(initialState: S, resolver: @escaping Reducer) {
        self.expectActionCriteriaQueue = []
        super.init(initialState: initialState, resolver: resolver)
    }
    override func notify(action: A) {
        if let expectActionCriteria = expectActionCriteriaQueue.first {
            expectActionCriteria(action)
            expectActionCriteriaQueue.removeFirst(1)
        }
    }
    func pushExpectActionCriteria(expectActionCriteria: @escaping ExpectActionCriteria) {
        expectActionCriteriaQueue.append(expectActionCriteria)
    }
}
