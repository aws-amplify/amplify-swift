//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// What an app needs to set up TOTP during sign-in.
///
/// Mirrors Amplify core's `TOTPSetupDetails`, including `getSetupURI(appName:accountName:)`.
@_spi(AmplifyExperimental)
public struct AuthClientTOTPSetupDetails {

    /// Secret code returned by the service to help setting up TOTP
    public let sharedSecret: String

    /// username that will be used to construct the URI
    public let username: String

    public init(sharedSecret: String, username: String) {
        self.sharedSecret = sharedSecret
        self.username = username
    }

    /// Returns a TOTP setup URI that can help the customers avoid barcode scanning and use native
    /// password manager to handle TOTP association.
    /// Example: On iOS and MacOS, URI will redirect to associated Password Manager for the platform
    ///
    /// - Parameters:
    ///   - appName: The issuer an authenticator app shows, such as the app's name.
    ///   - accountName: The account an authenticator app shows; `username` when `nil`.
    /// - Returns: An `otpauth://totp/` URI carrying the shared secret.
    /// - Throws: `AuthClientError.validation(field: "appName or accountName")` if `URL(string:)` cannot form
    ///   a URL from the parameters (on OS versions that do not percent-encode it, a character that is
    ///   illegal in a URL).
    public func getSetupURI(
        appName: String,
        accountName: String? = nil
    ) throws -> URL {
        guard let url = URL(
            string: "otpauth://totp/\(appName):\(accountName ?? username)?secret=\(sharedSecret)&issuer=\(appName)"
        ) else {
            throw AuthClientError.validation(
                field: "appName or accountName",
                "Invalid Parameters. Cannot form URL from the supplied appName or accountName",
                "Please make sure that the supplied parameters don't contain any characters that are illegal in a URL or is an empty String"
            )
        }
        return url
    }
}

extension AuthClientTOTPSetupDetails: Equatable {}

extension AuthClientTOTPSetupDetails: Sendable {}

extension AuthClientTOTPSetupDetails: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {

    /// Redacted: the shared secret never reaches a log through string interpolation, `print`, `debugPrint`,
    /// `dump`, or a sign-in step that carries these details. Stricter than the plugin's `TOTPSetupDetails`,
    /// which is not redacted.
    public var description: String {
        "AuthClientTOTPSetupDetails(sharedSecret: <redacted>, username: \(username))"
    }

    public var debugDescription: String {
        description
    }

    /// For `dump` and debuggers: the username, and the secret redacted.
    public var customMirror: Mirror {
        Mirror(self, children: ["sharedSecret": "<redacted>", "username": username], displayStyle: .struct)
    }
}
