//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension AuthRule {
    func getOwnerFieldOrDefault() -> String {
        return (ownerField != nil) ? ownerField!.stringValue : "owner"
    }

    func getModelOperationsOrDefault() -> [ModelOperation] {
        return operations.isEmpty ? [.create, .update, .delete, .read] : operations
    }
}
