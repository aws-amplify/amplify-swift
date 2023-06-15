//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Amplify

public struct VerifyTOTPSetupOptions {

    /// Device name that would be provided to Cognito when setting up TOTP
    public let friendlyDeviceName: String?

    public init(friendlyDeviceName: String? = nil) {
        self.friendlyDeviceName = friendlyDeviceName
    }
}
