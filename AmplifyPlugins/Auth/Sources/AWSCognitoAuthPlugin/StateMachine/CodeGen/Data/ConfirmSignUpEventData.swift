//// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct ConfirmSignUpEventData: Codable {
    public let username: String
    public let confirmationCode: String

    public init(username: String, confirmationCode: String) {
        self.username = username
        self.confirmationCode = confirmationCode
    }
}

extension ConfirmSignUpEventData: Equatable { }

extension ConfirmSignUpEventData: CustomDebugDictionaryConvertible {
    public var debugDictionary: [String: Any] {
        [
            "username": username.masked(),
            "confirmationCode": confirmationCode.masked(),
        ]
    }
}
extension ConfirmSignUpEventData: CustomDebugStringConvertible {
    public var debugDescription: String {
        debugDictionary.debugDescription
    }
}
