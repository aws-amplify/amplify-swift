//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

struct AppIDMetadata {
    let name: String

    init?(name: String?) {
        guard let name = name, !name.isEmpty else { return nil }
        self.name = name
    }
}

extension AppIDMetadata: CustomStringConvertible {

    var description: String {
        return "app/\(name.userAgentToken)"
    }
}
