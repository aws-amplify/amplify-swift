//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSCognitoIdentity
import AWSCognitoIdentityProvider

public extension AWSCognitoAuthPlugin {

    func federateToIdentityPool(
        withProviderToken: String,
        for provider: AuthProvider,
        options: AuthFederateToIdentityPoolRequest.Options? = nil
    ) async throws -> FederateToIdentityPoolResult {

        let options = options ?? AuthFederateToIdentityPoolRequest.Options()
        let request = AuthFederateToIdentityPoolRequest(token: withProviderToken, provider: provider, options: options)
        let task = AWSAuthFederateToIdentityPoolTask(request, authStateMachine: authStateMachine)
        return try await task.value

    }

    func clearFederationToIdentityPool(
        options: AuthClearFederationToIdentityPoolRequest.Options? = nil
    ) async throws {
        let options = options ?? AuthClearFederationToIdentityPoolRequest.Options()
        let request = AuthClearFederationToIdentityPoolRequest(options: options)
        let task = AWSAuthClearFederationToIdentityPoolTask(request, authStateMachine: authStateMachine)
        try await task.value
    }

    func fetchMFAPreference(
        options: FetchMFAPreferenceRequest.Options? = nil
    ) async throws -> UserMFAPreference {
        let options = options ?? FetchMFAPreferenceRequest.Options()
        let request = FetchMFAPreferenceRequest(options: options)
        fatalError("HS: Implement me")
    }

    func updateMFAPreference(
        sms: MFAPreference?,
        totp: MFAPreference?,
        options: UpdateMFAPreferenceRequest.Options? = nil
    ) async throws {
        let options = options ?? UpdateMFAPreferenceRequest.Options()
        let request = UpdateMFAPreferenceRequest(options: options)
        fatalError("HS: Implement me")
    }
    
}
