//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// Protocol for replicating `URLSession` behavior
// Note: Additional behavior can be added later if necessary
public protocol URLSessionClientBehavior {
    
    /// For testing only. Resets the state of the object in preparation for testing.
    func cancelAndReset() async
    
    func data(
        for request: URLRequest,
        delegate: (URLSessionTaskDelegate)?
    ) async throws -> (Data, URLResponse)
    
    func data(
        from url: URL,
        delegate: (URLSessionTaskDelegate)?
    ) async throws -> (Data, URLResponse)
    
}
