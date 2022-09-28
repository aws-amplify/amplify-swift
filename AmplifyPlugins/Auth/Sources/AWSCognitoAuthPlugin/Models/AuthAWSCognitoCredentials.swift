//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSPluginsCore

public struct AuthAWSCognitoCredentials: AWSTemporaryCredentials {

    public let  accessKey: String

    public let  secretKey: String

    public let  sessionKey: String

    public let  expiration: Date
}

extension AuthAWSCognitoCredentials: Codable { }

extension AuthAWSCognitoCredentials: Equatable { }

extension AuthAWSCognitoCredentials: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "accessKey": accessKey.masked(interiorCount: 5),
            "secretKey": secretKey.masked(interiorCount: 5),
            "sessionKey": sessionKey.masked(interiorCount: 5),
            "expiration": expiration
        ]
    }
}

extension AuthAWSCognitoCredentials: CustomDebugStringConvertible {
    public var debugDescription: String {
        debugDictionary.debugDescription
    }
}
