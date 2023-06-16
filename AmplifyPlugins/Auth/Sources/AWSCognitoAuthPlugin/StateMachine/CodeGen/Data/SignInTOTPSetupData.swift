//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

struct SignInTOTPSetupData {

    let secretCode: String
    let session: String
    let username: String

}

extension SignInTOTPSetupData: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "secretCode": secretCode.masked(),
            "session": session.masked(),
            "username": username.masked()
        ]
    }
}

extension SignInTOTPSetupData: Codable { }

extension SignInTOTPSetupData: Equatable { }
