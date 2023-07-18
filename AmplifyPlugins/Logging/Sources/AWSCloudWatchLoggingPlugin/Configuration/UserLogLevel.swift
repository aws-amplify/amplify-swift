//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public struct UserLogLevel: Codable {
    public init(
        defaultLogLevel: LogLevel,
        categoryLogLevel: [String: LogLevel]
    ) {
        self.defaultLogLevel = defaultLogLevel
        self.categoryLogLevel = categoryLogLevel
    }
    
    public let defaultLogLevel: LogLevel
    public let categoryLogLevel: [String: LogLevel]
}
