//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public extension ModelRegistry {

    /// - Warning: Although this has `public` access, it is intended for internal use and should not be used directly
    ///   by host applications. The behavior of this may change without warning.
    static var hasSyncableModels: Bool {
        if #available(iOS 13.0, *) {
            return modelSchemas.contains { !$0.isSystem }
        } else {
            return false
        }
    }
}
