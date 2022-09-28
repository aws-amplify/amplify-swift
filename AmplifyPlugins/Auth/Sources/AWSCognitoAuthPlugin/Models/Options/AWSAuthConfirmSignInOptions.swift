//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Amplify

public struct AWSAuthConfirmSignInOptions {

    /// User attributes to be passed in when confirming a sign with NEW_PASSWORD_REQUIRED challenge
    public let userAttributes: [AuthUserAttribute]?

    public let metadata: [String: String]?

    public init(userAttributes: [AuthUserAttribute]? = nil, metadata: [String: String]? = nil) {
        self.userAttributes = userAttributes
        self.metadata = metadata
    }
}
