//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import AWSCognitoIdentity
import ClientRuntime

extension InitiateAuthInput: Decodable {
    enum CodingKeys: String, CodingKey {
        case authFlow
        case authParameters
        case clientId
        case clientMetadata
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let authFlow = try values.decodeIfPresent(CognitoIdentityProviderClientTypes.AuthFlowType.self, forKey: .authFlow)
        let authParameters = try values.decodeIfPresent([String: String].self, forKey: .authParameters)
        let clientId = try values.decodeIfPresent(String.self, forKey: .clientId)
        let clientMetadata = try values.decodeIfPresent([String: String].self, forKey: .clientMetadata)
        self.init(
            authFlow: authFlow,
            authParameters: authParameters,
            clientId: clientId,
            clientMetadata: clientMetadata)
    }
}
