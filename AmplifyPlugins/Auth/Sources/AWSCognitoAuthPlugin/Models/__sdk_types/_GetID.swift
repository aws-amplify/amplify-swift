//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/26/23.
//

import Foundation

/// Input to the GetId action.
struct GetIdInput: Equatable {
    /// A standard AWS account ID (9+ digits).
    var accountId: String?
    /// An identity pool ID in the format REGION:GUID.
    /// This member is required.
    var identityPoolId: String?
    /// A set of optional name-value pairs that map provider names to provider tokens. The available provider names for Logins are as follows:
    ///
    /// * Facebook: graph.facebook.com
    ///
    /// * Amazon Cognito user pool: cognito-idp..amazonaws.com/, for example, cognito-idp.us-east-1.amazonaws.com/us-east-1_123456789.
    ///
    /// * Google: accounts.google.com
    ///
    /// * Amazon: www.amazon.com
    ///
    /// * Twitter: api.twitter.com
    ///
    /// * Digits: www.digits.com
    var logins: [String:String]?

    enum CodingKeys: String, CodingKey {
        case accountId = "AccountId"
        case identityPoolId = "IdentityPoolId"
        case logins = "Logins"
    }
}


/// Returned in response to a GetId request.
struct GetIdOutputResponse: Equatable {
    /// A unique identifier in the format REGION:GUID.
    var identityId: String?

    enum CodingKeys: String, CodingKey {
        case identityId = "IdentityId"
    }
}
