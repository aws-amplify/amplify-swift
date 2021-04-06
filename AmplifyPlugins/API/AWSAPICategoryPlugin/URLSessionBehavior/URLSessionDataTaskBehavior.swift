//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// Encapsulates the behavior required for a single HTTP operation, including
/// identifying, pausing/resuming, and cancelling. Behind the scenes, this will be
/// backed by a URLSessionTask.
public protocol URLSessionDataTaskBehavior: Cancellable, Resumable {
    /// Uniquely identifies this task in the local system. This identifier is not
    /// guaranteed to be globally unique
    var taskBehaviorIdentifier: Int { get }

    /// The response containing http status code, response headers, etc.
    var taskBehaviorResponse: URLResponse? { get }
}
