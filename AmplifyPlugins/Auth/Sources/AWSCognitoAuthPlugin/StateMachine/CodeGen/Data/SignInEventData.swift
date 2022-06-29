//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

struct SignInEventData {

    let username: String?

    let password: String?

    let signInMethod: SignInMethod

    init(username: String?,
         password: String?,
         signInMethod: SignInMethod = .unknown) {
        self.username = username
        self.password = password
        self.signInMethod = signInMethod
    }
}

extension SignInEventData: Equatable { }

extension SignInEventData: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "username": username.masked(),
            "password": password.redacted()
        ]
    }
}
extension SignInEventData: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
