//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

package struct SignUpEventData {

    package let username: String
    package let clientMetadata: [String: String]?
    package let validationData: [String: String]?
    package var session: String?

    package init(
        username: String,

         clientMetadata: [String: String]? = nil,
        validationData: [String: String]? = nil,
        session: String? = nil
    ) {
        self.username = username
        self.clientMetadata = clientMetadata
        self.validationData = validationData
        self.session = session
    }
}


extension SignUpEventData: Equatable { }

extension SignUpEventData: CustomDebugDictionaryConvertible {
    package var debugDictionary: [String: Any] {
        [
            "username": username.maskedForLog(),
            "clientMetadata": clientMetadata ?? "",
            "validationData": validationData ?? "",
            "session": session?.maskedForLog() ?? ""
        ]
    }
}

extension SignUpEventData: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}

extension SignUpEventData: Codable { }
