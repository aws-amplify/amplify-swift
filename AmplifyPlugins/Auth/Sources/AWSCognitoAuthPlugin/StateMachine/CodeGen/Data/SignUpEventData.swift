//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Amplify

struct SignUpEventData {

    let username: String
    let clientMetadata: [String: String]?
    let validationData: [String: String]?
    var session: String?
    
    init(username: String, 
         clientMetadata: [String: String]? = nil,
         validationData: [String: String]? = nil,
         session: String? = nil) {
        self.username = username
        self.clientMetadata = clientMetadata
        self.validationData = validationData
        self.session = session
    }
}


extension SignUpEventData: Equatable { }

extension SignUpEventData: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "username": username.masked(),
            "clientMetadata": clientMetadata ?? "",
            "validationData": validationData ?? "",
            "session": session?.masked() ?? ""
        ]
    }
}

extension SignUpEventData: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}

extension SignUpEventData: Codable { }
