//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import Foundation

@_spi(AmplifyExperimental)
public struct LoggingConstraints: Codable, Sendable {
    public init(
        defaultLogLevel: LogLevel = .error,
        namespaceLogLevel: [String: LogLevel] = [:],
        userLogLevel: [String: UserLogLevel] = [:]
    ) {
        self.defaultLogLevel = defaultLogLevel
        self.namespaceLogLevel = namespaceLogLevel
        self.userLogLevel = userLogLevel
    }

    public let defaultLogLevel: LogLevel
    public let namespaceLogLevel: [String: LogLevel]?
    public let userLogLevel: [String: UserLogLevel]?
}

@_spi(AmplifyExperimental)
public struct UserLogLevel: Codable, Sendable {
    public init(
        defaultLogLevel: LogLevel,
        namespaceLogLevel: [String: LogLevel]
    ) {
        self.defaultLogLevel = defaultLogLevel
        self.namespaceLogLevel = namespaceLogLevel
    }

    public let defaultLogLevel: LogLevel
    public let namespaceLogLevel: [String: LogLevel]
}
