//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Defines the auth session behavior
public protocol AuthSession {

    /// Indicates whether a user is signed in or not
    ///
    /// `true` if a user is authenticated. `isSignedIn` remains `true` till we call `Amplify.Auth.signOut`.
    /// Please note that this value remains `true` even when the session is expired. Refer the underlying plugin
    /// documentation regarding how to handle session expiry.
    var isSignedIn: Bool { get }
}
