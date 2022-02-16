//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct ConfirmSignUpEventData: Codable {
    let username: String
    let confirmationCode: String

    init(username: String, confirmationCode: String) {
        self.username = username
        self.confirmationCode = confirmationCode
    }
}

extension ConfirmSignUpEventData: Equatable { }

extension ConfirmSignUpEventData: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "username": username.masked(),
            "confirmationCode": confirmationCode.masked(),
        ]
    }
}
extension ConfirmSignUpEventData: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
