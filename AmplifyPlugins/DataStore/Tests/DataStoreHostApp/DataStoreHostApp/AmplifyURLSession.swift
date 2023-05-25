//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Foundation
import Amplify
import AWSAPIPlugin

enum AmplifyURLSessionState {
    case active
    case inactive
}

class AmplifyURLSessionNoOperationDataTask: URLSessionDataTaskBehavior {
    var taskBehaviorIdentifier: Int

    var taskBehaviorResponse: URLResponse?

    init(taskBehaviorIdentifier: Int, taskBehaviorResponse: URLResponse? = nil) {
        self.taskBehaviorIdentifier = taskBehaviorIdentifier
        self.taskBehaviorResponse = taskBehaviorResponse
    }

    static let shared: AmplifyURLSessionNoOperationDataTask =
        AmplifyURLSessionNoOperationDataTask(taskBehaviorIdentifier: -1)

    func cancel() { }

    func pause() { }

    func resume() { }

}

class AmplifyURLSession {
    private let queue = DispatchQueue(label: "AmplifyURLSession")
    private var state: AmplifyURLSessionState
    let session: URLSession

    init(state: AmplifyURLSessionState, session: URLSession) {
        self.state = state
        self.session = session
    }

    convenience init(session: URLSession) {
        self.init(state: .active, session: session)
    }
}

extension AmplifyURLSession: URLSessionBehavior {
    func cancelAndReset() async {
        queue.sync {
            state = .inactive
        }
        await session.cancelAndReset()
    }

    func dataTaskBehavior(with request: URLRequest) -> URLSessionDataTaskBehavior {
        queue.sync {
            switch state {
            case .active:
                return session.dataTask(with: request)
            default:
                return AmplifyURLSessionNoOperationDataTask.shared
            }
        }
    }

    var sessionBehaviorDelegate: URLSessionBehaviorDelegate? {
        return session.sessionBehaviorDelegate
    }

}
