//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public struct LoggingConstraints: Codable {
    public init(
        defaultLogLevel: LogLevel = .error,
        categoryLogLevel: [String: LogLevel] = [:],
        userLogLevel: [String: UserLogLevel] = [:]
    ) {
        self.defaultLogLevel = defaultLogLevel
        self.categoryLogLevel = categoryLogLevel
        self.userLogLevel = userLogLevel
    }
    
    public let defaultLogLevel: LogLevel
    public let categoryLogLevel: [String: LogLevel]?
    public let userLogLevel: [String: UserLogLevel]?
}
