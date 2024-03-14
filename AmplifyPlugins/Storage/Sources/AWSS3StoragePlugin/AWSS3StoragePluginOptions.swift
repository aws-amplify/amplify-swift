//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public struct AWSS3StoragePluginOptions {
    public let defaultAccessLevel: StorageAccessLevel

    public init(defaultAccessLevel: StorageAccessLevel = .guest) {
        self.defaultAccessLevel = defaultAccessLevel
    }
}
