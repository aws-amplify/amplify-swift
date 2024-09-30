//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

struct UserAgentMetadata {}

extension UserAgentMetadata: CustomStringConvertible {

    var description: String {
        "ua/2.1"
    }
}
