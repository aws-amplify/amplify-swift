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
    func federateToIdentityPool(
        withProviderToken: String,
        for provider: AuthProvider,
        options: AuthFederateToIdentityPoolRequest.Options?
    ) async throws -> FederateToIdentityPoolResult

    /// Clear federation to identity pool
    ///
    /// - Parameters:
    ///   - options: Parameters specific to plugin behavior.
    func clearFederationToIdentityPool(options: AuthClearFederationToIdentityPoolRequest.Options?) async throws

}
