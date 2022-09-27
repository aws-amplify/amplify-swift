//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct AWSAuthSignUpOptions {

    public let validationData: [String: String]?

    public let metadata: [String: String]?

    public init(validationData: [String: String]? = nil, metadata: [String: String]? = nil) {
        self.validationData = validationData
        self.metadata = metadata
    }
}
