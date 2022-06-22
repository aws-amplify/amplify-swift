//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCognitoIdentity
import AWSCognitoIdentityProvider

public extension AWSCognitoAuthPlugin {

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
