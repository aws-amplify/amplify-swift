//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

package struct SignInTOTPSetupData {

    package let secretCode: String
    package let session: String
    package let username: String

    package init(
        secretCode: String,
        session: String,
        username: String
    ) {
        self.secretCode = secretCode
        self.session = session
        self.username = username
    }
}

extension SignInTOTPSetupData: CustomDebugDictionaryConvertible {
    package var debugDictionary: [String: Any] {
        [
            "sharedSecret": secretCode.redactedForLog(),
            "session": session.maskedForLog(),
            "username": username.maskedForLog()
        ]
    }
}

extension SignInTOTPSetupData: Codable { }

extension SignInTOTPSetupData: Equatable { }
