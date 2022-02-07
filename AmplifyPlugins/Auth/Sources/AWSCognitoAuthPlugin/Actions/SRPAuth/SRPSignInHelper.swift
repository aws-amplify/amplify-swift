//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import CryptoKit

struct SRPSignInHelper {

    static func srpEnvironment(_ environment: Environment) throws
    -> SRPAuthEnvironment {

        guard let environment = environment as? SRPAuthEnvironment else {
            let message = "SRP Environment configured incorrectly"
            let error = SRPSignInError.configuration(message: message)
            throw error
        }
        return environment
    }

    static func srpClient(_ environment: SRPAuthEnvironment) throws
    -> SRPClientBehavior {
        let nHexValue = environment.srpConfiguration.nHexValue
        let gHexValue = environment.srpConfiguration.gHexValue

        do {
            let factory = environment.srpClientFactory
            return try factory(nHexValue, gHexValue)
        } catch let error as SRPError {
            let error = SRPSignInError.calculation(error)
            throw error
        } catch {
            let message = "SRP Client failed to initialize"
            let error = SRPSignInError.configuration(message: message)
            throw error
        }
    }

    static func clientSecretHash(
        username: String,
        userPoolClientId: String,
        clientSecret: String
    ) -> String {
        let clientSecretData = clientSecret.data(using: .utf8)!
        let clientSecretByteArray = [UInt8](clientSecretData)
        let key = SymmetricKey(data: clientSecretByteArray)

        let clientData = (username + userPoolClientId).data(using: .utf8)!

        let mac = HMAC<SHA256>.authenticationCode(for: clientData, using: key)
        let macBase64 = Data(mac).base64EncodedString()
        return macBase64
    }
}
