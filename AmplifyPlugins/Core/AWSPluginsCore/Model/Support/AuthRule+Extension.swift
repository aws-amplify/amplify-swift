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

    func getModelOperationsOrDefault() -> [ModelOperation] {
        return operations.isEmpty ? [.create, .update, .delete, .read] : operations
    }
}
