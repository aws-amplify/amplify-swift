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

    /// name of the model
    public let modelName: String?

    public init(authType: AWSAuthorizationType?, modelName: String?) {
        self.authType = authType
        self.modelName = modelName
    }
}
