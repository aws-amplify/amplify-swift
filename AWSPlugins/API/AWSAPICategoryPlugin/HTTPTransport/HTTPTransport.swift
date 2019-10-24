//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// Encapsulates the behavior required for AWSAPICategoryPlugin to fulfill network
/// requests. Behind the scenes, this will be backed by a URLSessionTask.
protocol HTTPTransport {

    /// For testing only. Resets the state of the object in preparation for testing.
    func reset(onComplete: BasicClosure?)

    /// Returns an HTTPTransportTask for the specified request
    /// - Parameter request: The URLRequest to fulfill
    func task(for request: URLRequest) -> HTTPTransportTask

    /// The HTTPTransportTaskDelegate that will be notified of lifecycle and data
    /// for this task
    var delegate: HTTPTransportTaskDelegate? { get set }
}
