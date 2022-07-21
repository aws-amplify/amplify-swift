//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Defines URLSession behaviors used during fulfillment of API tasks
public protocol URLSessionBehaviorDelegate: AnyObject {
    func urlSessionBehavior(_ session: URLSessionBehavior,
                            dataTaskBehavior: URLSessionDataTaskBehavior,
                            didCompleteWithError error: Error?)

    func urlSessionBehavior(_ session: URLSessionBehavior,
                            dataTaskBehavior: URLSessionDataTaskBehavior,
                            didReceive data: Data)

}

public extension URLSessionBehaviorDelegate {
    var asURLSessionDelegate: (URLSessionDelegate & URLSessionTaskDelegate)? {
        return self as? URLSessionDelegate & URLSessionTaskDelegate
    }
}
