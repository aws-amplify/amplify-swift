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

    /// A map of custom key-value pairs that you can provide as input for any custom workflows that this action triggers.
    public let metadata: [String: String]?

    /// Device name that would be provided to Cognito when setting up TOTP
    public let friendlyDeviceName: String?

    public init(
        userAttributes: [AuthUserAttribute]? = nil,
        metadata: [String: String]? = nil,
        friendlyDeviceName: String? = nil) {
            self.userAttributes = userAttributes
            self.metadata = metadata
            self.friendlyDeviceName = friendlyDeviceName
        }
}
