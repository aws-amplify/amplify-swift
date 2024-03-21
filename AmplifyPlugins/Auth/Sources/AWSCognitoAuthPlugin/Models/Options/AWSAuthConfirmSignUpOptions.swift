//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct AWSAuthConfirmSignUpOptions {

    public let metadata: [String: String]?

    public let forceAliasCreation: Bool?

    public init(metadata: [String: String]? = nil,
                forceAliasCreation: Bool? = nil) {
        self.metadata = metadata
        self.forceAliasCreation = forceAliasCreation
    }
}
