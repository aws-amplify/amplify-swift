//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension URLSessionTask: URLSessionDataTaskBehavior {
    public var taskBehaviorResponse: URLResponse? {
        response
    }

    public var taskBehaviorIdentifier: Int {
        taskIdentifier
    }

    public func pause() {
        suspend()
    }
}
