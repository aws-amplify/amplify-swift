//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

struct SignedOutData {

    let lastKnownUserName: String?
    let hostedUIError: AWSCognitoHostedUIError?
    let globalSignOutError: AWSCognitoGlobalSignOutError?
    let revokeTokenError: AWSCognitoRevokeTokenError?

    init(
        lastKnownUserName: String? = nil,
        hostedUIError: AWSCognitoHostedUIError? = nil,
        globalSignOutError: AWSCognitoGlobalSignOutError? = nil,
        revokeTokenError: AWSCognitoRevokeTokenError? = nil
    ) {
        self.lastKnownUserName = lastKnownUserName
        self.hostedUIError = hostedUIError
        self.globalSignOutError = globalSignOutError
        self.revokeTokenError = revokeTokenError
    }
}

extension SignedOutData: Equatable {
    static func == (lhs: SignedOutData, rhs: SignedOutData) -> Bool {
        return lhs.lastKnownUserName == rhs.lastKnownUserName &&
        lhs.globalSignOutError?.accessToken == rhs.globalSignOutError?.accessToken &&
        lhs.revokeTokenError?.refreshToken == rhs.revokeTokenError?.refreshToken

    }
}

extension SignedOutData: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "lastKnownUserName": lastKnownUserName.masked()
        ]
    }
}

extension SignedOutData: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
