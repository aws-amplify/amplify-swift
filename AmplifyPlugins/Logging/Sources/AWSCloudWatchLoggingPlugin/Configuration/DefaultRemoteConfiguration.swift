//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public struct DefaultRemoteConfiguration: Codable {
    public init(
        endpoint: URL,
        refreshIntervalInSeconds: Int = 1200
    ) {
        self.endpoint = endpoint
        self.refreshIntervalInSeconds = refreshIntervalInSeconds
    }
    
    public let endpoint: URL
    public let refreshIntervalInSeconds: Int
}
