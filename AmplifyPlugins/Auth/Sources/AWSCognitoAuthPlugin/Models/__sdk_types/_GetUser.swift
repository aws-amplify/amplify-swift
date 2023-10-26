//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/26/23.
//

import Foundation

/// Represents the request to get information about the user.
struct GetUserInput: Equatable {
    /// A non-expired access token for the user whose information you want to query.
    /// This member is required.
    var accessToken: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "AccessToken"
    }
}

/// Represents the response from the server from the request to get information about the user.
struct GetUserOutputResponse: Equatable {
    /// This response parameter is no longer supported. It provides information only about SMS MFA configurations. It doesn't provide information about time-based one-time password (TOTP) software token MFA configurations. To look up information about either type of MFA configuration, use UserMFASettingList instead.
    var mfaOptions: [CognitoIdentityProviderClientTypes.MFAOptionType]?
    /// The user's preferred MFA setting.
    var preferredMfaSetting: String?
    /// An array of name-value pairs representing user attributes. For custom attributes, you must prepend the custom: prefix to the attribute name.
    /// This member is required.
    var userAttributes: [CognitoIdentityProviderClientTypes.AttributeType]?
    /// The MFA options that are activated for the user. The possible values in this list are SMS_MFA and SOFTWARE_TOKEN_MFA.
    var userMFASettingList: [String]?
    /// The username of the user that you requested.
    /// This member is required.
    var username: String?

    enum CodingKeys: String, CodingKey {
        case mfaOptions = "MFAOptions"
        case preferredMfaSetting = "PreferredMfaSetting"
        case userAttributes = "UserAttributes"
        case userMFASettingList = "UserMFASettingList"
        case username = "Username"
    }
}
