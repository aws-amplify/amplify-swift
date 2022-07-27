//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

struct SignInEventData {

    let username: String?

    let password: String?

    let clientMetadata: [String: String]

    let deviceMetadata: DeviceMetadata

    let signInMethod: SignInMethod

    init(username: String?,
         password: String?,
         clientMetadata: [String: String] = [:],
         deviceMetadata: DeviceMetadata = .noData,
         signInMethod: SignInMethod = .unknown) {
        self.username = username
        self.password = password
        self.clientMetadata = clientMetadata
        self.deviceMetadata = deviceMetadata
        self.signInMethod = signInMethod
    }
}

extension SignInEventData: Equatable { }

extension SignInEventData: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "username": username.masked(),
            "password": password.redacted(),
            "clientMetadata": clientMetadata,
            "deviceMetadata": deviceMetadata,
            "signInMethod": signInMethod
        ]
    }
}
extension SignInEventData: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
