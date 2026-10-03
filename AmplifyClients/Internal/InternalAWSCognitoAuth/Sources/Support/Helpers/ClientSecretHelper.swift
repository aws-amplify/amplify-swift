//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import CryptoKit
import Foundation

package enum ClientSecretHelper {

    package static func calculateSecretHash(
        username: String,
        userPoolConfiguration: UserPoolConfigurationData
    ) -> String? {
        let userPoolClientId = userPoolConfiguration.clientId
        if let clientSecret = userPoolConfiguration.clientSecret {

            return Self.clientSecretHash(
                username: username,
                userPoolClientId: userPoolClientId,
                clientSecret: clientSecret
            )
        }
        return nil
    }

    package static func clientSecretHash(
        username: String,
        userPoolClientId: String,
        clientSecret: String
    ) -> String {
        let clientSecretData = Data(clientSecret.utf8)
        let clientSecretByteArray = [UInt8](clientSecretData)
        let key = SymmetricKey(data: clientSecretByteArray)

        let clientData = Data((username + userPoolClientId).utf8)

        let mac = HMAC<SHA256>.authenticationCode(for: clientData, using: key)
        let macBase64 = Data(mac).base64EncodedString()
        return macBase64
    }

}
