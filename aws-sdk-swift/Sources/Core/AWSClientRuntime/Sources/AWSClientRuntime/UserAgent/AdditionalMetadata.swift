//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct AdditionalMetadata {
    let name: String
    let value: String?

    init(name: String, value: String? = nil) {
        self.name = name
        self.value = value
    }
}

extension AdditionalMetadata: CustomStringConvertible {

    var description: String {
        if let value {
            return "md/\(name.userAgentTokenNoHash)#\(value.userAgentToken)"
        } else {
            return "md/\(name.userAgentTokenNoHash)"
        }
    }
}
