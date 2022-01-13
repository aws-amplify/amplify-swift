//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//



public struct UserPoolConfigurationData: Equatable {

    public let poolId: String
    public let clientId: String
    public let region: String
    public let clientSecret: String?
    public let pinpointAppId: String?
    public let hostedUIConfig: HostedUIConfigurationData?

    public init(poolId: String,
                clientId: String,
                region: String,
                clientSecret: String? = nil,
                pinpointAppId: String? = nil,
                hostedUIConfig: HostedUIConfigurationData? = nil)
    {
        self.poolId = poolId
        self.clientId = clientId
        self.region = region
        self.clientSecret = clientSecret
        self.pinpointAppId = pinpointAppId
        self.hostedUIConfig = hostedUIConfig
    }

}

extension UserPoolConfigurationData: Codable { }

extension UserPoolConfigurationData: CustomDebugDictionaryConvertible {
    public var debugDictionary: [String: Any] {
        [
            "poolId": poolId.masked(interiorCount: 4, retainingCount: 4),
            "clientId": clientId.masked(interiorCount: 4, retainingCount: 4),
            "region": region.masked(interiorCount: 4, retainingCount: 4),
            "clientSecret": clientSecret.masked(interiorCount: 4),
            "pinpointAppId": pinpointAppId.masked(interiorCount: 4, retainingCount: 4),
            "hostedUI": hostedUIConfig?.debugDescription ?? "NA"
        ]
    }
}

extension UserPoolConfigurationData: CustomDebugStringConvertible {
    public var debugDescription: String {
        debugDictionary.debugDescription
    }
}


