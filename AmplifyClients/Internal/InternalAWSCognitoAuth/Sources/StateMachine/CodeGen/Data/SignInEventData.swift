//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

package struct SignInEventData {

    package let username: String?

    package let password: String?

    package let clientMetadata: [String: String]

    package let signInMethod: SignInMethod

    package let session: String?

    package private(set) var presentationAnchor: EnginePresentationAnchor?

    package init(
        username: String?,
        password: String?,
        clientMetadata: [String: String] = [:],
        signInMethod: SignInMethod,
        session: String? = nil,
        presentationAnchor: EnginePresentationAnchor? = nil
    ) {
        self.username = username
        self.password = password
        self.clientMetadata = clientMetadata
        self.signInMethod = signInMethod
        self.session = session
        self.presentationAnchor = presentationAnchor
    }

    package var authFlowType: EngineAuthFlowType? {
        if case .apiBased(let authFlowType) = signInMethod {
            return authFlowType
        }
        return nil
    }

}

extension SignInEventData: Equatable { }

extension SignInEventData: CustomDebugDictionaryConvertible {
    package var debugDictionary: [String: Any] {
        [
            "username": username.maskedForLog(),
            "password": password.redactedForLog(),
            "clientMetadata": clientMetadata,
            "signInMethod": signInMethod,
            "session": session?.redactedForLog() ?? ""
        ]
    }
}
extension SignInEventData: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}

extension SignInEventData: Codable {
    private enum CodingKeys: String, CodingKey {
        case username, password, clientMetadata, signInMethod, session
    }
}
