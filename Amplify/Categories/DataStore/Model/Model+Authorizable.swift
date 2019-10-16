//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Model where Self: Authorizable {
    public static func rule(allow: AuthStrategy,
                            forField field: CodingKey? = nil,
                            provider: AuthProvider? = nil,
                            ownerField: CodingKey? = nil,
                            identityClaim: String? = nil,
                            groupClaim: String? = nil,
                            groups: [String] = [],
                            groupsField: CodingKey? = nil,
                            operations: ModelOperation...) -> AuthRule {
        return AuthRule(allow: allow,
                        field: field,
                        provider: provider,
                        ownerField: ownerField,
                        identityClaim: identityClaim,
                        groupClaim: groupClaim,
                        groups: groups,
                        groupsField: groupsField,
                        operations: operations)
    }
}
