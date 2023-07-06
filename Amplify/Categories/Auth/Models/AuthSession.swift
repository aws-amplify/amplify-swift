//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Defines the auth session behavior
public protocol AuthSession {

    /// True if the current user has signed in
    ///
    /// `true` if a user has authenticated, via any of:
    /// - ``AuthCategoryBehavior/signIn(username:password:options:)``
    /// - ``AuthCategoryBehavior/signInWithWebUI(presentationAnchor:options:)``
    /// - ``AuthCategoryBehavior/signInWithWebUI(for:presentationAnchor:options:)``
    /// - A plugin-specific sign in method like
    ///   `AWSCognitoAuthPlugin.federateToIdentityPool(withProviderToken:for:options:)`
    ///
    /// `isSignedIn` remains `true` until we call `Amplify.Auth.signOut`. Notably, this value remains `true`
    /// even when the session is expired. Refer the underlying plugin documentation regarding how to handle session expiry.
    var isSignedIn: Bool { get }
}
