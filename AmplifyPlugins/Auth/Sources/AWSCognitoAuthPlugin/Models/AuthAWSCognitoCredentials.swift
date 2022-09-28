//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSPluginsCore

public struct AuthAWSCognitoCredentials: AWSTemporaryCredentials {

    public let  accessKeyId: String

    public let  secretAccessKey: String

    public let  sessionKey: String

    public let  expiration: Date
}

extension AuthAWSCognitoCredentials: Codable { }

extension AuthAWSCognitoCredentials: Equatable { }

extension AuthAWSCognitoCredentials: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "accessKey": accessKeyId.masked(interiorCount: 5),
            "secretAccessKey": secretAccessKey.masked(interiorCount: 5),
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
