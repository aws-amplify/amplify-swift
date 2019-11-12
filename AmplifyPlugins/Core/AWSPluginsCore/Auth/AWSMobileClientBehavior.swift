//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCore
import AWSMobileClient

// Behavior that the implemenation class for AWSMobileClient will use.
protocol AWSMobileClientBehavior {

    // Returns a `AWSCognitoCredentialsProvider`, used to instantiate other dependencies with.
    func getCognitoCredentialsProvider() -> AWSCognitoCredentialsProvider

    /// Get/retrieve the identity id for this provider. If an identity id is already set on this provider, no remote
    /// call is made and the identity will be returned as a result of the AWSTask (the identityId is also available
    /// as a property). If no identityId is set on this provider, one will be retrieved from the service.
    ///
    /// - Returns: Asynchronous task which contains the identity id or error.
    func getIdentityId() -> AWSTask<NSString>

    /// Returns cached UserPools auth JWT tokens if valid.
    /// If the `idToken` is not valid, and a refresh token is available, refresh token is used to get a new `idToken`.
    /// If there is no refresh token and the user is signed in, a notification is dispatched to indicate requirement
    /// of user to re-signin.
    /// The call to wait will be synchronized so that if multiple threads call this method, they will block till the
    /// first thread gets the token.
    ///
    /// - Parameter completionHandler: Tokens if available, else error.
    func getTokens(completionHandler: @escaping (Tokens?, Error?) -> Void)
}
