//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
public class MockOperationQueue: OperationQueue {

    private var mockOperationCount: Int = 0
    override public var operationCount: Int {
        return mockOperationCount
    }
    override public func addOperation(_ operation: Operation) {
        mockOperationCount += 1
    }
}
