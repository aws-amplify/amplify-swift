//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

// No-listener versions of the public APIs, to clean call sites that use Combine
// publishers to get results

public extension AuthCategoryBehavior {

    /// Fetch the current authentication session.
    ///
    /// - Parameters:
    ///   - options: Parameters specific to plugin behavior
    func fetchAuthSession(
        options: AuthFetchSessionOperation.Request.Options? = nil
    ) -> AuthFetchSessionOperation {
        fetchAuthSession(options: options, listener: nil)
    }
}
