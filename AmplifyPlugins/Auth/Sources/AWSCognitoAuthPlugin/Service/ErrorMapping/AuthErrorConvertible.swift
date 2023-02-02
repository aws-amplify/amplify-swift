//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

/// A type that can be represented as an AuthError
///
protocol AuthErrorConvertible {

    var authError: AuthError { get }
}

extension AuthError: AuthErrorConvertible {
    var authError: AuthError {
        return self
    }
}
