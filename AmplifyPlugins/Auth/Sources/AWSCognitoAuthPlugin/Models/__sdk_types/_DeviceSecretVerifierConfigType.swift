//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/26/23.
//

import Foundation

extension CognitoIdentityProviderClientTypes {
    /// The device verifier against which it is authenticated.
    struct DeviceSecretVerifierConfigType: Equatable {
        /// The password verifier.
        var passwordVerifier: String?
        /// The [salt](https://en.wikipedia.org/wiki/Salt_(cryptography))
        var salt: String?

        init(
            passwordVerifier: String? = nil,
            salt: String? = nil
        )
        {
            self.passwordVerifier = passwordVerifier
            self.salt = salt
        }
    }
}
