//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

package struct SignedOutData {

    package let lastKnownUserName: String?
    package let hostedUIError: EngineHostedUISignOutFailure?
    package let globalSignOutError: EngineGlobalSignOutFailure?
    package let revokeTokenError: EngineRevokeTokenFailure?

    package init(
        lastKnownUserName: String? = nil,
        hostedUIError: EngineHostedUISignOutFailure? = nil,
        globalSignOutError: EngineGlobalSignOutFailure? = nil,
        revokeTokenError: EngineRevokeTokenFailure? = nil
    ) {
        self.lastKnownUserName = lastKnownUserName
        self.hostedUIError = hostedUIError
        self.globalSignOutError = globalSignOutError
        self.revokeTokenError = revokeTokenError
    }
}

extension SignedOutData: Equatable {
    package static func == (lhs: SignedOutData, rhs: SignedOutData) -> Bool {
        return lhs.lastKnownUserName == rhs.lastKnownUserName &&
        lhs.globalSignOutError?.accessToken == rhs.globalSignOutError?.accessToken &&
        lhs.revokeTokenError?.refreshToken == rhs.revokeTokenError?.refreshToken

    }
}

extension SignedOutData: CustomDebugDictionaryConvertible {
    package var debugDictionary: [String: Any] {
        [
            "lastKnownUserName": lastKnownUserName.maskedForLog()
        ]
    }
}

extension SignedOutData: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}
