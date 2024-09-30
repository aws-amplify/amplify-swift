//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime

struct LanguageMetadata {
    let version: String
    let additionalMetadata: [AdditionalMetadata]

    init(version: String = swiftVersion, additionalMetadata: [AdditionalMetadata] = []) {
        self.version = version
        self.additionalMetadata = additionalMetadata
    }
 }

extension LanguageMetadata: CustomStringConvertible {

    var description: String {
        let description = "lang/swift#\(version.userAgentToken)"
        return ([description] + additionalMetadata.map(\.description)).joined(separator: " ")
    }
}
