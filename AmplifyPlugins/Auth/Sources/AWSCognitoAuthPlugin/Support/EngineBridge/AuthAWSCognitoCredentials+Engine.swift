//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import InternalAWSCognitoAuth

// Conversions between the public `AuthAWSCognitoCredentials` and the engine's `EngineAWSCredentials`.
// Both directions copy the four stored properties as they are, so a round trip in either direction gives an equal value.

extension AuthAWSCognitoCredentials {

    /// The public value of engine credentials, for the plugin's API (`AWSAuthCognitoSession`,
    /// `FederateToIdentityPoolResult`). Uses the internal memberwise initializer: the type has no public
    /// one.
    init(_ credentials: EngineAWSCredentials) {
        self.init(
            accessKeyId: credentials.accessKeyId,
            secretAccessKey: credentials.secretAccessKey,
            sessionToken: credentials.sessionToken,
            expiration: credentials.expiration
        )
    }
}

extension EngineAWSCredentials {

    /// The engine value of public credentials.
    init(_ credentials: AuthAWSCognitoCredentials) {
        self.init(
            accessKeyId: credentials.accessKeyId,
            secretAccessKey: credentials.secretAccessKey,
            sessionToken: credentials.sessionToken,
            expiration: credentials.expiration
        )
    }
}
