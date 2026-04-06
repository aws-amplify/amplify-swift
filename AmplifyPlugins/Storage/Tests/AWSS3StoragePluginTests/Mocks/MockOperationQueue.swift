//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public class MockOperationQueue: OperationQueue, @unchecked Sendable {

    public var size = 0

    override public func addOperation(_ operation: Operation) {
        size += 1
    }
}
