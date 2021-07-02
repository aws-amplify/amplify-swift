//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

/// Plugin specific options type
public struct AWSPluginOptions {

    /// authorization type
    public let authType: AWSAuthorizationType?

    public init(authType: AWSAuthorizationType?) {
        self.authType = authType
    }
}
