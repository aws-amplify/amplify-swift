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
        options: AuthFederateToIdentityPoolRequest.Options? = nil,
        listener: AWSAuthFederateToIdentityPoolOperation.ResultListener?
    ) -> AWSAuthFederateToIdentityPoolOperation {

        let options = options ?? AuthFederateToIdentityPoolRequest.Options()
        let request = AuthFederateToIdentityPoolRequest(
            token: withProviderToken,
            provider: provider,
            options: options)
        let operation = AWSAuthFederateToIdentityPoolOperation(
            request,
            authConfiguration: authConfiguration,
            authStateMachine: authStateMachine,
            resultListener: listener)

        queue.addOperation(operation)
        return operation
    }

    func clearFederationToIdentityPool(
        options: AuthClearFederationToIdentityPoolRequest.Options? = nil,
        listener: AWSAuthClearFederationToIdentityPoolOperation.ResultListener?
    ) -> AWSAuthClearFederationToIdentityPoolOperation {

        let options = options ?? AuthClearFederationToIdentityPoolRequest.Options()
        let request = AuthClearFederationToIdentityPoolRequest(
            options: options)
        let operation = AWSAuthClearFederationToIdentityPoolOperation(
            request,
            authConfiguration: authConfiguration,
            authStateMachine: authStateMachine,
            resultListener: listener)

        queue.addOperation(operation)
        return operation

    }

    func getEscapeHatch() -> AWSCognitoAuthService {
        var service: AWSCognitoAuthService?
        switch authConfiguration {

        case .userPools:
            let userPoolClient = try? authEnvironment.cognitoUserPoolFactory()
            if let client = userPoolClient as? CognitoIdentityProviderClient {
                service = .userPool(client)
            }

        case .identityPools:

            let identityPoolClient = try? authEnvironment.cognitoIdentityFactory()
            if let client = identityPoolClient as? CognitoIdentityClient {
                service = .identityPool(client)
            }

        case .userPoolsAndIdentityPools:
            let userPoolClient = try? authEnvironment.cognitoUserPoolFactory()
            let identityPoolClient = try? authEnvironment.cognitoIdentityFactory()
            if let userPoolClient = userPoolClient
                as? CognitoIdentityProviderClient,
               let identityPoolClient = identityPoolClient
                as? CognitoIdentityClient {

                service = .userPoolAndIdentityPool(userPoolClient,
                                                   identityPoolClient)
            }
        case .none:
            service = nil
        }
        guard let service = service else {
            fatalError("""
            Could not find any escape hatch, invoke Amplify configuration
            before accessing the escape hatch.
            """)
        }
        return service
    }
}
