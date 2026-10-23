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

    public init(sharedSecret: String, username: String) {
        self.sharedSecret = sharedSecret
        self.username = username
    }
    /// Returns a TOTP setup URI that can help the customers avoid barcode scanning and use native password manager to handle TOTP association
    /// Example: On iOS and MacOS, URI will redirect to associated Password Manager for the platform
    ///
    /// throws AuthError.validation if a `URL` cannot be formed with the supplied parameters
    /// (for example, if the parameter string contains characters that are illegal in a URL, or is an empty string).
    public func getSetupURI(
        appName: String,
        accountName: String? = nil
    ) throws -> URL {
            guard let URL = URL(
                string: "otpauth://totp/\(appName):\(accountName ?? username)?secret=\(sharedSecret)&issuer=\(appName)")
            else {

                throw AuthError.validation(
                    "appName or accountName",
                    "Invalid Parameters. Cannot form URL from the supplied appName or accountName",
                    "Please make sure that the supplied parameters don't contain any characters that are illegal in a URL or is an empty String",
                    nil
                )
            }
            return URL
        }

}

extension TOTPSetupDetails: Equatable { }

extension TOTPSetupDetails: Sendable { }

extension TOTPSetupDetails: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {

    /// The default struct printing, with the shared secret redacted: the details are logged as part of a sign-in or
    /// TOTP setup result, and the secret lets anyone generate the user's TOTP codes. Use `sharedSecret` or
    /// `getSetupURI(appName:accountName:)` for the value.
    public var description: String {
        "\(String(reflecting: Self.self))(sharedSecret: \(String(reflecting: Self.redactedSecret)), "
            + "username: \(String(reflecting: username)))"
    }

    public var debugDescription: String {
        description
    }

    /// For `dump` and debuggers: the shared secret redacted.
    public var customMirror: Mirror {
        Mirror(self, children: ["sharedSecret": Self.redactedSecret, "username": username], displayStyle: .struct)
    }

    private static let redactedSecret = "<REDACTED>"
}
