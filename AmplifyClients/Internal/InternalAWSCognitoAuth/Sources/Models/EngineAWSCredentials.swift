//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import Foundation

/// The engine's copy of the plugin's public `AuthAWSCognitoCredentials`
/// (`AWSCognitoAuthPlugin/Models/AuthAWSCognitoCredentials.swift`).
///
/// It is persisted in every identity-pool case of `AmplifyCredentials`, so the stored properties, their
/// names, types and order, the synthesized `Codable` and the synthesized `Equatable` are the public
/// type's. The two types encode to the same JSON tree and decode each other's encoding.
/// The debug output is the public type's too, so log lines that
/// print credentials do not change.
///
/// It conforms to AmplifyFoundation's `AWSTemporaryCredentials`. The public type keeps AWSPluginsCore's
/// `AWSTemporaryCredentials` in the plugin. The plugin converts between the two in
/// `Support/EngineBridge/AuthAWSCognitoCredentials+Engine.swift`.
package struct EngineAWSCredentials: AWSTemporaryCredentials {

    package let accessKeyId: String

    package let secretAccessKey: String

    package let sessionToken: String

    package let expiration: Date

    /// The memberwise initializer, as the public type's synthesized one.
    package init(
        accessKeyId: String,
        secretAccessKey: String,
        sessionToken: String,
        expiration: Date
    ) {
        self.accessKeyId = accessKeyId
        self.secretAccessKey = secretAccessKey
        self.sessionToken = sessionToken
        self.expiration = expiration
    }

    /// A copy of the plugin's `AuthAWSCognitoCredentials.doesExpire(in:)`
    /// (`Support/Helpers/AuthAWSCognitoCredentials+Validation.swift`), measured from `now`, which defaults
    /// to the current time.
    package func doesExpire(in seconds: TimeInterval = 0, at now: Date = Date()) -> Bool {

        let currentTime = now.addingTimeInterval(seconds)
        return currentTime > expiration
    }
}

extension EngineAWSCredentials: Codable { }

extension EngineAWSCredentials: Equatable { }

extension EngineAWSCredentials: Sendable { }

extension EngineAWSCredentials: CustomDebugDictionaryConvertible {
    /// The same keys and masking as the public type's `debugDictionary`.
    package var debugDictionary: [String: Any] {
        [
            "accessKey": accessKeyId.maskedForLog(interiorCount: 5),
            "secretAccessKey": secretAccessKey.maskedForLog(interiorCount: 5),
            "sessionToken": sessionToken.maskedForLog(interiorCount: 5),
            "expiration": expiration
        ]
    }
}

extension EngineAWSCredentials: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}
