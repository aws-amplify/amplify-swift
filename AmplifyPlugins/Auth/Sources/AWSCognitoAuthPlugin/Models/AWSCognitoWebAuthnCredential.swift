//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public struct AWSCognitoWebAuthnCredential: AuthWebAuthnCredential {
    public let credentialId: String
    public let createdAt: Date
    public let relyingPartyId: String
    public let friendlyName: String?

    init(
        credentialId: String,
        createdAt: Date,
        relyingPartyId: String,
        friendlyName: String? = nil
    ) {
        self.credentialId = credentialId
        self.createdAt = createdAt
        self.friendlyName = friendlyName
        self.relyingPartyId = relyingPartyId
    }
}
