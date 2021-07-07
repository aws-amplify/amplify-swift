//
//  File.swift
//  
//
//  Created by Costantino, Diego on 2021-07-07.
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
