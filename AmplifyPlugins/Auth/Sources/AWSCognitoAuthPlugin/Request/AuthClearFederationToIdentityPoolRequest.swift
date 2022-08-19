//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// Request for Federating to identity pool
public struct AuthClearFederationToIdentityPoolRequest: AmplifyOperationRequest {

    /// Extra request options defined in `AuthClearFederationToIdentityPoolRequest.Options`
    public var options: Options

    public init(options: Options) {
        self.options = options
    }
}

public extension AuthClearFederationToIdentityPoolRequest {

    struct Options {

        public init() { }
    }
}
