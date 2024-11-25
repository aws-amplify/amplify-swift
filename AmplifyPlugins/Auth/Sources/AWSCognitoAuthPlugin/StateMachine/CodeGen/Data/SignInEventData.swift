//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
import typealias Amplify.AuthUIPresentationAnchor
#endif

struct SignInEventData {

    let username: String?

    let password: String?

    let clientMetadata: [String: String]

    let signInMethod: SignInMethod
    
    let session: String?

    private(set) var presentationAnchor: AuthUIPresentationAnchor? = nil

    init(
        username: String?,
        password: String?,
        clientMetadata: [String: String] = [:],
        signInMethod: SignInMethod,
        session: String? = nil,
        presentationAnchor: AuthUIPresentationAnchor? = nil
    ) {
        self.username = username
        self.password = password
        self.clientMetadata = clientMetadata
        self.signInMethod = signInMethod
        self.session = session
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
            "signInMethod": signInMethod,
            "session": session?.redacted() ?? ""
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
        case username, password, clientMetadata, signInMethod, session
    }
}
