//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(watchOS)

import Foundation

typealias AuthUIPresentationAnchor = AuthUIPresentationAnchorPlaceholder

/// This class serves as a placeholder for the AuthUIPresentationAnchor, which is not available in watchOS.
/// It cannot be initialized and exists strictly to facilitate cross-platform compilation without requiring compiler
/// checks thorughout the codebase.
class AuthUIPresentationAnchorPlaceholder: Equatable {
    
    private init() {}
    
    public static func == (lhs: AuthUIPresentationAnchorPlaceholder,
                           rhs: AuthUIPresentationAnchorPlaceholder) -> Bool {
        true
    }
}

#endif
