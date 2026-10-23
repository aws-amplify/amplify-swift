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

// Every printed form is the redacted one. The data rides in `SetUpTOTPEvent.waitForAnswer`, whose verbose line
// prints the event by reflection, and in `SignInTOTPSetupState`, so default printing would log the shared secret.
extension SignInTOTPSetupData: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {

    package var description: String {
        debugDictionary.debugDescription
    }

    package var debugDescription: String {
        description
    }

    /// For `dump` and debuggers: the secret redacted, the session and the username masked.
    package var customMirror: Mirror {
        Mirror(
            self,
            children: [
                "secretCode": secretCode.redactedForLog(),
                "session": session.maskedForLog(),
                "username": username.maskedForLog()
            ],
            displayStyle: .struct
        )
    }
}

extension SignInTOTPSetupData: Codable { }

extension SignInTOTPSetupData: Equatable { }
