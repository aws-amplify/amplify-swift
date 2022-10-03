//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime

struct UserPoolConfigurationData: Equatable {

    let poolId: String
    let clientId: String
    let region: String
    let endpoint: CustomEndpoint?
    let clientSecret: String?
    let pinpointAppId: String?
    let hostedUIConfig: HostedUIConfigurationData?
    let authFlowType: AuthFlowType

    init(
        poolId: String,
        clientId: String,
        region: String,
        endpoint: CustomEndpoint? = nil,
        clientSecret: String? = nil,
        pinpointAppId: String? = nil,
        authFlowType: AuthFlowType = .userSRP,
        hostedUIConfig: HostedUIConfigurationData? = nil
    ) {
        self.poolId = poolId
        self.clientId = clientId
        self.region = region
        self.endpoint = endpoint
        self.clientSecret = clientSecret
        self.pinpointAppId = pinpointAppId
        self.hostedUIConfig = hostedUIConfig
        self.authFlowType = authFlowType
    }

    /// Amazon Cognito user pool: cognito-idp.<region>.amazonaws.com/<YOUR_USER_POOL_ID>,
    /// for example, cognito-idp.us-east-1.amazonaws.com/us-east-1_123456789.
    func getIdentityProviderName() -> String {
        return "cognito-idp.\(region).amazonaws.com/\(poolId)"
    }
}

extension UserPoolConfigurationData: Codable { }

extension UserPoolConfigurationData: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "poolId": poolId.masked(interiorCount: 4, retainingCount: 4),
            "clientId": clientId.masked(interiorCount: 4, retainingCount: 4),
            "region": region.redacted(),
            "endpoint": endpoint ?? "N/A",
            "clientSecret": clientSecret.masked(interiorCount: 4),
            "pinpointAppId": pinpointAppId.masked(interiorCount: 4, retainingCount: 4),
            "hostedUI": hostedUIConfig?.debugDescription ?? "N/A"
        ]
    }
}

extension UserPoolConfigurationData: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}

extension UserPoolConfigurationData {
    struct CustomEndpoint: Equatable, Codable {
        let validatedHost: String

        var resolver: AWSEndpointResolving {
            AWSEndpointResolving(Endpoint(host: validatedHost))
        }
    }
}

extension UserPoolConfigurationData.CustomEndpoint {
    init(endpoint: String, validator: (String) throws -> Endpoint) rethrows {
        let endpoint = try validator(endpoint)
        validatedHost = endpoint.host
    }
}
