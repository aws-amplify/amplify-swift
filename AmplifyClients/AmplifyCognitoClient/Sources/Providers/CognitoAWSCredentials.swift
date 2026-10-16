//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import Foundation
import InternalAWSCognitoAuth

/// Temporary AWS credentials vended by a session.
///
/// Internal and concrete, so it can cross from the session actor: `any AWSCredentials` is not
/// `Sendable`. It is upcast only inside the provider's nonisolated `resolve()`.
struct CognitoAWSCredentials: AWSTemporaryCredentials, Sendable, Equatable {
    let accessKeyId: String
    let secretAccessKey: String
    let sessionToken: String
    let expiration: Date
}

extension CognitoAWSCredentials: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {

    /// Redacted, as `AuthClientAWSCredentials` is: what `credentialsProvider.resolve()` returns never puts the
    /// secret or the session token in a log through string interpolation.
    var debugDescription: String {
        "CognitoAWSCredentials(accessKeyId: \(maskedAccessKeyId), secretAccessKey: <redacted>, sessionToken: <redacted>, expiration: \(expiration))"
    }

    var description: String {
        debugDescription
    }

    /// For `dump` and debuggers: the key ID masked, the secret and the session token redacted.
    var customMirror: Mirror {
        Mirror(
            self,
            children: [
                "accessKeyId": maskedAccessKeyId,
                "secretAccessKey": "<redacted>",
                "sessionToken": "<redacted>",
                "expiration": expiration
            ],
            displayStyle: .struct
        )
    }

    /// Masked as the plugin's `AuthAWSCognitoCredentials` masks it.
    private var maskedAccessKeyId: String {
        accessKeyId.maskedForLog(interiorCount: 5)
    }
}
