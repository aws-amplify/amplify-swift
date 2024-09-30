//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

struct SDKMetadata {
    let version: String
    let additionalMetadata: [AdditionalMetadata]

    init(version: String, additionalMetadata: [AdditionalMetadata] = []) {
        self.version = version
        self.additionalMetadata = additionalMetadata
    }
}

extension SDKMetadata: CustomStringConvertible {

    var description: String {
        let description = "aws-sdk-swift/\(version.userAgentToken)"
        return ([description] + additionalMetadata.map(\.description)).joined(separator: " ")
    }
}
