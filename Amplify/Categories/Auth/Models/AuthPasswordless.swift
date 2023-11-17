//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Auth Passwordless flow types
///
/// `.signUpAndSignIn` will create a new user and initiate signing in the user
/// `signIn` will initiate signing in an existing user
public enum AuthPasswordlessFlow {
    case signUpAndSignIn(
        userAttributes: [String: String]?,
        clientMetadata: [String: String]?
    )
    case signIn(clientMetadata: [String: String]?)
}

/// Delivery destination for the Auth Passwordless flows
///
/// For One Time Password, it can be either .`phone` or `.email`
/// For Magic Link, it is `.email`
public enum AuthPasswordlessDeliveryDestination {
   case phone
   case email
}
