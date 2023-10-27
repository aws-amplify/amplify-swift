//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/26/23.
//

import Foundation

extension CognitoIdentityProviderClientTypes {
    /// The type used for enabling software token MFA at the user level. If an MFA type is activated for a user, the user will be prompted for MFA during all sign-in attempts, unless device tracking is turned on and the device has been trusted. If you want MFA to be applied selectively based on the assessed risk level of sign-in attempts, deactivate MFA for users and turn on Adaptive Authentication for the user pool.
    struct SoftwareTokenMfaSettingsType: Equatable, Codable {
        /// Specifies whether software token MFA is activated. If an MFA type is activated for a user, the user will be prompted for MFA during all sign-in attempts, unless device tracking is turned on and the device has been trusted.
        var enabled: Bool
        /// Specifies whether software token MFA is the preferred MFA method.
        var preferredMfa: Bool

        init(
            enabled: Bool = false,
            preferredMfa: Bool = false
        )
        {
            self.enabled = enabled
            self.preferredMfa = preferredMfa
        }
    }

}
