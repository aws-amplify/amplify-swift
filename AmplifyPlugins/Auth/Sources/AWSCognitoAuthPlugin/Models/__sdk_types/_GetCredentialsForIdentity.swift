//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/26/23.
//

import Foundation

/// Input to the GetCredentialsForIdentity action.
struct GetCredentialsForIdentityInput: Equatable {
    /// The Amazon Resource Name (ARN) of the role to be assumed when multiple roles were received in the token from the identity provider. For example, a SAML-based identity provider. This parameter is optional for identity providers that do not support role customization.
    var customRoleArn: String?
    /// A unique identifier in the format REGION:GUID.
    /// This member is required.
    var identityId: String?
    /// A set of optional name-value pairs that map provider names to provider tokens. The name-value pair will follow the syntax "provider_name": "provider_user_identifier". Logins should not be specified when trying to get credentials for an unauthenticated identity. The Logins parameter is required when using identities associated with external identity providers such as Facebook. For examples of Logins maps, see the code examples in the [External Identity Providers](https://docs.aws.amazon.com/cognito/latest/developerguide/external-identity-providers.html) section of the Amazon Cognito Developer Guide.
    var logins: [String:String]?

    enum CodingKeys: String, CodingKey {
        case customRoleArn = "CustomRoleArn"
        case identityId = "IdentityId"
        case logins = "Logins"
    }
}


/// Returned in response to a successful GetCredentialsForIdentity operation.
struct GetCredentialsForIdentityOutputResponse: Equatable {
    /// Credentials for the provided identity ID.
    var credentials: CognitoIdentityClientTypes.Credentials?
    /// A unique identifier in the format REGION:GUID.
    var identityId: String?

    enum CodingKeys: String, CodingKey {
        case credentials = "Credentials"
        case identityId = "IdentityId"
    }
}
