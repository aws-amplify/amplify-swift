//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct AWSUpdateUserAttributeOptions {

    public let metadata: [String: String]?

    public init(metadata: [String: String]? = nil) {
        self.metadata = metadata
    }
}
