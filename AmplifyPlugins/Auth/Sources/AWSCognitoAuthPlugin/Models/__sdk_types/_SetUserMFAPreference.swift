//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/26/23.
//

import Foundation

struct SetUserMFAPreferenceInput: Equatable {
    /// A valid access token that Amazon Cognito issued to the user whose MFA preference you want to set.
    /// This member is required.
    var accessToken: String?
    /// The SMS text message multi-factor authentication (MFA) settings.
    var smsMfaSettings: CognitoIdentityProviderClientTypes.SMSMfaSettingsType?
    /// The time-based one-time password (TOTP) software token MFA settings.
    var softwareTokenMfaSettings: CognitoIdentityProviderClientTypes.SoftwareTokenMfaSettingsType?

    enum CodingKeys: String, CodingKey {
        case accessToken = "AccessToken"
        case smsMfaSettings = "SMSMfaSettings"
        case softwareTokenMfaSettings = "SoftwareTokenMfaSettings"
    }
}

struct SetUserMFAPreferenceOutputResponse: Equatable {}
