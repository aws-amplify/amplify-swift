//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// Request for Federating to identity pool
public struct AuthFederateToIdentityPoolRequest: AmplifyOperationRequest {

    public let token: String

    public let provider: AuthProvider

    /// Extra request options defined in `FederateToIdentityPoolRequest.Options`
    public var options: Options

    public init(token: String,
                provider: AuthProvider,
                options: Options) {
        self.token = token
        self.provider = provider
        self.options = options
    }
}

public extension AuthFederateToIdentityPoolRequest {

    struct Options {

        public let developerProvidedIdentityID: String?

        public init(developerProvidedIdentityID: String? = nil) {
                self.developerProvidedIdentityID = developerProvidedIdentityID
            }
    }
}
