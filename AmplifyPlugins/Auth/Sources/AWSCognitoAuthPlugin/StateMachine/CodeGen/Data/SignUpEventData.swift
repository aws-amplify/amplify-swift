//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct SignUpEventData: Codable {
    let username: String
    let password: String
    let attributes: [String: String]

    init(username: String,
         password: String,
         attributes: [String: String]) {
        self.username = username
        self.password = password
        self.attributes = attributes
    }
}

extension SignUpEventData: Equatable { }

extension SignUpEventData: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "username": username.masked(),
            "password": password.redacted()
        ]
    }
}
extension SignUpEventData: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
