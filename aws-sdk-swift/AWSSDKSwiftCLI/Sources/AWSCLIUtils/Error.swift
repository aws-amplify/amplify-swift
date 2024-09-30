//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct Error: LocalizedError {
    public var message: String
    public var errorDescription: String? { message }

    public init(_ message: String) {
        self.message = message
    }
}
