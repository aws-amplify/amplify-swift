//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Auth Passwordless flow types
///


public enum AuthPasswordlessFlow {
    /// `.signUpAndSignIn` will create a new user and initiate signing in the user
    case signUpAndSignIn
    
    /// `.signIn` will initiate signing in an existing user
    case signIn
}
