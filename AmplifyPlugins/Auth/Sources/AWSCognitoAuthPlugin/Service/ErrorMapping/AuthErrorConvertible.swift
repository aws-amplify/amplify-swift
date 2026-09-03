//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// A type that can be represented as an AuthError
///
/// - Note: `Sendable` because these errors are thrown out of actor-isolated auth work.
protocol AuthErrorConvertible: Sendable {
    var authError: AuthError { get }
}

extension AuthError: AuthErrorConvertible {
    var authError: AuthError {
        return self
    }
}
