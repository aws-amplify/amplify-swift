//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension AuthRule {
    func getOwnerFieldOrDefault() -> String {
        guard let ownerField = ownerField else {
            return "owner"
        }
        return ownerField
    }

    func isReadRestrictingStaticGroup() -> Bool {
        return allow == .groups &&
            !groups.isEmpty &&
            getModelOperationsOrDefault().contains(.read)
    }

    func isReadRestrictingOwner() -> Bool {
        return allow == .owner &&
            getModelOperationsOrDefault().contains(.read)
    }

    func getModelOperationsOrDefault() -> [ModelOperation] {
        return operations.isEmpty ? [.create, .update, .delete, .read] : operations
    }

    public func identityClaimOrDefault() -> String {
        guard let identityClaim = self.identityClaim else {
            return "username"
        }
        if identityClaim == "cognito:username" {
            return "username"
        }
        return identityClaim
    }
}

extension Array where Element == AuthRule {
    func readRestrictingStaticGroups() -> Set<String> {
        var readRestrictingStaticGroups = Set<String>()
        let readRestrictingGroupRules = filter { $0.isReadRestrictingStaticGroup() }
        for groupRules in readRestrictingGroupRules {
            groupRules.groups.forEach { group in
                readRestrictingStaticGroups.insert(group)
            }
        }
        return readRestrictingStaticGroups
    }

    func readRestrictingOwnerRules() -> [AuthRule] {
        return filter { $0.isReadRestrictingOwner() }
    }
}
