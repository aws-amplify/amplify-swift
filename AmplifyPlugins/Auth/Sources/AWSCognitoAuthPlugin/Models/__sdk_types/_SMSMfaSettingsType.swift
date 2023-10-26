//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/26/23.
//

import Foundation

extension CognitoIdentityProviderClientTypes {
    /// The type used for enabling SMS multi-factor authentication (MFA) at the user level. Phone numbers don't need to be verified to be used for SMS MFA. If an MFA type is activated for a user, the user will be prompted for MFA during all sign-in attempts, unless device tracking is turned on and the device has been trusted. If you would like MFA to be applied selectively based on the assessed risk level of sign-in attempts, deactivate MFA for users and turn on Adaptive Authentication for the user pool.
    struct SMSMfaSettingsType: Equatable {
        /// Specifies whether SMS text message MFA is activated. If an MFA type is activated for a user, the user will be prompted for MFA during all sign-in attempts, unless device tracking is turned on and the device has been trusted.
        var enabled: Bool
        /// Specifies whether SMS is the preferred MFA method.
        var preferredMfa: Bool

        enum CodingKeys: String, CodingKey {
            case enabled = "Enabled"
            case preferredMfa = "PreferredMfa"
        }
    }
}
