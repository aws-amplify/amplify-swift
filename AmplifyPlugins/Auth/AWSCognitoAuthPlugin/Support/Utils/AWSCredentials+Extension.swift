//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCore
import Amplify

extension AWSCredentials {

    func toAmplifyAWSCredentials() throws -> AuthAWSCognitoCredentials {

        // Credentials are fetched through Cognito Identity Pool and thus these are temporary credentials
        // so sessionKey and expiration date should not be nil.
        let nonNilAccessKey = accessKey
        let nonNilSecretKey = secretKey
        guard let nonNilSessionKey = sessionKey,
              let nonNilExpiration = expiration,
              !nonNilAccessKey.isEmpty,
              !nonNilSecretKey.isEmpty else {
                  let error = AuthError.unknown("""
                      Could not retreive AWS credentials, credential value is nil or empty.
                      """)
                  throw error
              }

        return AuthAWSCognitoCredentials(accessKey: nonNilAccessKey,
                                         secretKey: nonNilSecretKey,
                                         sessionKey: nonNilSessionKey,
                                         expiration: nonNilExpiration)
    }
}
