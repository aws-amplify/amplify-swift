//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

class MockPublisherOperation: AmplifyOperation<MockPublisherRequest, Int, APIError> {
    typealias Responder = (MockPublisherOperation) -> Void
    let responder: Responder

    init(responder: @escaping Responder, resultListener: ResultListener? = nil) {
        self.responder = responder
        super.init(
            categoryType: .api,
            eventName: .mockPublisherOperation,
            request: MockPublisherRequest(),
            resultListener: resultListener
        )
    }

    override func main() {
        DispatchQueue.global().async {
            self.responder(self)
        }
    }

}
