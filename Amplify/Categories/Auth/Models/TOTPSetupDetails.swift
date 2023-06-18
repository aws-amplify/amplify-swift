//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct TOTPSetupDetails {

    /// Secret code returned by the service to help setting up TOTP
    public let secretCode: String

    /// username that will be used to construct the URI
    public let username: String

    public init(secretCode: String, username: String) {
        self.secretCode = secretCode
        self.username = username
    }

    public func getSetupURI(
        appName: String,
        accountName: String? = nil) -> URL? {
            URL(string: "otpauth://totp/\(appName):\(accountName ?? username)?secret=\(secretCode)&issuer=\(appName)")
    }

}
