//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Methods to interact with the underlying operation triggered on task callbacks
protocol APIOperation {

    /// Get the operation's unique identifier
    func getOperationId() -> UUID

    /// Signal the operation on progress of new data from the data task
    func updateProgress(_ data: Data, response: URLResponse?)

    /// Signal on completion of the data task
    func complete(with error: Error?, response: URLResponse?)

    /// Signal the operation to be cancelled when the task is terminateds
    func cancelOperation()
}
