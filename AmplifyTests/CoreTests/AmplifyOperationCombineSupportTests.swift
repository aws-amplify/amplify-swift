//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine
import XCTest

import Amplify
@testable import AmplifyTestCommon


class MockPublisherOperation: AmplifyOperation<MockPublisherRequest, Int, APIError> {
    typealias Responder = (MockPublisherOperation) -> Void
    let responder: Responder

    init(responder: @escaping Responder, resultListener: ResultListener?) {
        self.responder = responder
        super.init(
            categoryType: .api,
            eventName: .mockPublisherOperation,
            request: MockPublisherRequest(),
            resultListener: resultListener
        )
    }

    override func main() {
        responder(self)
    }

}
