//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// Specifies the URLSession behavior required for AWSAPICategoryPlugin to fulfill
/// network requests. Behind the scenes, this will be backed by a URLSessionTask,
/// but specifying a protocol allows us to inject mocks for easier testing.
public protocol URLSessionBehavior {

    /// For testing only. Resets the state of the object in preparation for testing.
    func cancelAndReset() async

    /// Returns a data task for the specified request
    /// - Parameter request: The URLRequest to fulfill
    func dataTaskBehavior(with request: URLRequest) -> URLSessionDataTaskBehavior

    /// Returns the delegate assigned during initialization
    var sessionBehaviorDelegate: URLSessionBehaviorDelegate? { get }
}

public protocol URLSessionBehaviorFactory {
    func makeSession(withDelegate delegate: URLSessionBehaviorDelegate?) -> URLSessionBehavior
}
