//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct SignInEventData: Codable {
    public let username: String?
    public let password: String?

    public init(username: String?, password: String?) {
        self.username = username
        self.password = password
    }
}

extension SignInEventData: Equatable { }

extension SignInEventData: CustomDebugDictionaryConvertible {
    public var debugDictionary: [String: Any] {
        [
            "username": username.masked(),
            "password": password.redacted()
        ]
    }
}
extension SignInEventData: CustomDebugStringConvertible {
    public var debugDescription: String {
        debugDictionary.debugDescription
    }
}
