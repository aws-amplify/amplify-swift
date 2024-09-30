//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime

struct FrameworkMetadata {
    let name: String
    let version: String?
    let additionalMetadata: [AdditionalMetadata]

    init(name: String, version: String, additionalMetadata: [AdditionalMetadata] = []) {
        self.name = name
        self.version = version
        self.additionalMetadata = additionalMetadata
    }
 }

extension FrameworkMetadata: CustomStringConvertible {

    var description: String {
        var description = "lib/\(name.userAgentToken)"
        if let version = version, !version.isEmpty {
            description += "#\(version.userAgentToken)"
        }
        return ([description] + additionalMetadata.map(\.description)).joined(separator: " ")
    }
}
