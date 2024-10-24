//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import typealias Amplify.AuthUIPresentationAnchor

struct SignInEventData {

    let username: String?

    let password: String?

    let clientMetadata: [String: String]

    let signInMethod: SignInMethod

    private(set) var presentationAnchor: AuthUIPresentationAnchor? = nil

    init(
        username: String?,
        password: String?,
        clientMetadata: [String: String] = [:],
        signInMethod: SignInMethod,
        presentationAnchor: AuthUIPresentationAnchor? = nil
    ) {
        self.username = username
        self.password = password
        self.clientMetadata = clientMetadata
        self.signInMethod = signInMethod
        self.presentationAnchor = presentationAnchor
    }

    var authFlowType: AuthFlowType? {
        if case .apiBased(let authFlowType) = signInMethod {
            return authFlowType
        }
        return nil
    }

}

extension SignInEventData: Equatable { }

extension SignInEventData: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "username": username.masked(),
            "password": password.redacted(),
            "clientMetadata": clientMetadata,
            "signInMethod": signInMethod
        ]
    }
}
extension SignInEventData: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}

extension SignInEventData: Codable {
    private enum CodingKeys: String, CodingKey {
        case username, password, clientMetadata, signInMethod
    }
}
