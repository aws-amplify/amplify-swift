//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct SignUpEventData: Codable {
    public let username: String
    public let password: String

    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }
}

extension SignUpEventData: Equatable { }

extension SignUpEventData: CustomDebugDictionaryConvertible {
    public var debugDictionary: [String: Any] {
        [
            "username": username.masked(),
            "password": password.redacted(),
        ]
    }
}
extension SignUpEventData: CustomDebugStringConvertible {
    public var debugDescription: String {
        debugDictionary.debugDescription
    }
}
