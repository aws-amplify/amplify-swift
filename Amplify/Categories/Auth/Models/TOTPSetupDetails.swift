//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct TOTPSetupDetails {

    /// Secret code returned by the service to help setting up TOTP
    let secretCode: String

    /// username that will be used to construct the URI
    let username: String

    public init(secretCode: String, username: String) {
        self.secretCode = secretCode
        self.username = username
    }

    public func getSetupURI(
        appName: String,
        accountName: String? = nil) -> URL? {
            fatalError("HS: Implement me!!")
    }

}
