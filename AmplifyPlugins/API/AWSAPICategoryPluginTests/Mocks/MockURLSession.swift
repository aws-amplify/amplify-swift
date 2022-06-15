//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import AWSAPIPlugin
@testable import Amplify

class MockURLSession: URLSessionBehavior {
    weak var sessionBehaviorDelegate: URLSessionBehaviorDelegate?

    static let defaultOnReset: ((BasicClosure?) -> Void) = { $0?() }

    var onTaskForRequest: (URLRequest) -> URLSessionDataTaskBehavior
    var onReset: ((BasicClosure?) -> Void)?

    init(onTaskForRequest: @escaping (URLRequest) -> URLSessionDataTaskBehavior,
         onReset: ((BasicClosure?) -> Void)? = MockURLSession.defaultOnReset) {
        self.onTaskForRequest = onTaskForRequest
        self.onReset = onReset
    }

    func dataTaskBehavior(with request: URLRequest) -> URLSessionDataTaskBehavior {
        let task = onTaskForRequest(request)
        if let mockTask = task as? MockURLSessionTask {
            mockTask.mockSession = self
        }
        return task
    }

    func reset(onComplete: BasicClosure?) {
        onReset?(onComplete)
    }
    
    func cancelAndReset() async {
        // do nothing
    }
}
