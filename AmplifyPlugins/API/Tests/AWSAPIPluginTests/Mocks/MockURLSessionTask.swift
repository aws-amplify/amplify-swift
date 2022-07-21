//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import AWSAPIPlugin
@testable import Amplify
@testable import AmplifyTestCommon

class MockURLSessionTask: URLSessionDataTaskBehavior {
    static var counter = AtomicValue(initialValue: 0)

    /// Mimics a URLSessionTask's Session context, for dispatching events to the
    /// session delegate. Rather than use the mock session as a broker, the tests
    /// should directly invoke the appropriate methods on the mockSession's
    /// `delegate`
    weak var mockSession: MockURLSession?

    let taskBehaviorIdentifier: Int
    let taskBehaviorResponse: URLResponse?

    var onCancel: BasicClosure?
    var onPause: BasicClosure?
    var onResume: BasicClosure?

    init(onCancel: BasicClosure? = nil,
         onPause: BasicClosure? = nil,
         onResume: BasicClosure? = nil) {
        self.onCancel = onCancel
        self.onPause = onPause
        self.onResume = onResume
        self.taskBehaviorIdentifier = MockURLSessionTask.counter.increment()
        self.taskBehaviorResponse = URLResponse()
    }

    func cancel() {
        onCancel?()
    }

    func pause() {
        onPause?()
    }

    func resume() {
        onResume?()
    }
}
