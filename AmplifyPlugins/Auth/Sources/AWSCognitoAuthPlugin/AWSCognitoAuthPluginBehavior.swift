//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

protocol AWSCognitoAuthPluginBehavior: AuthCategoryPlugin {

    /// Provides access to the underlying AuthCognito service client.
    ///
    /// - Parameters:
    ///   - options: Parameters specific to plugin behavior.
    ///   - listener: Triggered when the operation completes.
    /// - Returns: AWSCognitoAuthService
    func getEscapeHatch() -> AWSCognitoAuthService

    /// Clear federation to identity pool
    ///
    /// - Parameters:
    ///   - withProviderToken: Provider token to start the federation for
    ///   - provider: Auth provider for the federation. See `Amplify.AuthProvider`
    ///   - options: Parameters specific to plugin behavior.
    ///   - listener: Triggered when the operation completes.
    /// - Returns: AWSAuthFederateToIdentityPoolOperation
    @discardableResult
    func federateToIdentityPool(
        withProviderToken: String,
        for provider: AuthProvider,
        options: AuthFederateToIdentityPoolRequest.Options?,
        listener: AWSAuthFederateToIdentityPoolOperation.ResultListener?
    ) -> AWSAuthFederateToIdentityPoolOperation

    /// Clear federation to identity pool
    ///
    /// - Parameters:
    ///   - options: Parameters specific to plugin behavior.
    ///   - listener: Triggered when the operation completes.
    /// - Returns: AWSAuthClearFederationToIdentityPoolOperation
    @discardableResult
    func clearFederationToIdentityPool(
        options: AuthClearFederationToIdentityPoolRequest.Options?,
        listener: AWSAuthClearFederationToIdentityPoolOperation.ResultListener?
    ) -> AWSAuthClearFederationToIdentityPoolOperation

}
