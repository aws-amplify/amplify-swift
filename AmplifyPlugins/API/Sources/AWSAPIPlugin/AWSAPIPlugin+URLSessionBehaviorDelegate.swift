//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension AWSAPIPlugin: URLSessionBehaviorDelegate {
    public func urlSessionBehavior(_ session: URLSessionBehavior,
                                   dataTaskBehavior: URLSessionDataTaskBehavior,
                                   didCompleteWithError error: Error?) {
        mapper.operation(for: dataTaskBehavior)?.complete(with: error, response: dataTaskBehavior.taskBehaviorResponse)
    }

    public func urlSessionBehavior(_ session: URLSessionBehavior,
                                   dataTaskBehavior: URLSessionDataTaskBehavior,
                                   didReceive data: Data) {
        mapper.operation(for: dataTaskBehavior)?.updateProgress(data, response: dataTaskBehavior.taskBehaviorResponse)
    }
}
