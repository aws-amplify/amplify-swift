//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct TOTPSetupDetails {

    /// Secret code returned by the service to help setting up TOTP
    public let sharedSecret: String

    /// username that will be used to construct the URI
    public let username: String

    public init(secretCode: String, username: String) {
        self.sharedSecret = secretCode
        self.username = username
    }

    public func getSetupURI(
        appName: String,
        accountName: String? = nil) throws -> URL {
            guard let URL = URL(
                string: "otpauth://totp/\(appName):\(accountName ?? username)?secret=\(sharedSecret)&issuer=\(appName)") else {
                
                /// throws if a `URL` cannot be formed with the string (for example, if the string contains characters that are illegal in a URL, or is an empty string).
                throw AuthError.validation(
                    "appName or accountName",
                    "Invalid Parameters. Cannot form URL from the supplied appName or accountName",
                    "Please make sure that the supplied parameters don't contain any characters that are illegal in a URL or is an empty String",
                    nil)
            }
            return URL
        }

}
