//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

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

    func fetchMFAPreference() async throws -> UserMFAPreference {
        let task = FetchMFAPreferenceTask(
            authStateMachine: authStateMachine,
            userPoolFactory: authEnvironment.cognitoUserPoolFactory)
        return try await task.value
    }

    func updateMFAPreference(
        sms: MFAPreference?,
        totp: MFAPreference?
    ) async throws {
        let task = UpdateMFAPreferenceTask(
            smsPreference: sms,
            totpPreference: totp,
            authStateMachine: authStateMachine,
            userPoolFactory: authEnvironment.cognitoUserPoolFactory)
        return try await task.value
    }
    
}
