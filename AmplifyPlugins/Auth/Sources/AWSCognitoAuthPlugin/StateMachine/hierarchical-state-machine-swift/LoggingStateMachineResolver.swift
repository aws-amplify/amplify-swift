//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import os.log

struct LoggingStateMachineResolver<Resolver: StateMachineResolver>: StateMachineResolver {
    typealias StateType = Resolver.StateType

    private let wrappedResolver: Resolver
    private let logger: OSLog
    private let logType: OSLogType

    static func makeDefaultLogger() -> OSLog {
        OSLog(subsystem: "StateMachineResolver", category: String(describing: StateType.self))
    }

    init(
        resolver: Resolver,
        logger: OSLog? = nil,
        level: OSLogType = .debug
    ) {
        self.wrappedResolver = resolver
        self.logger = logger ?? LoggingStateMachineResolver.makeDefaultLogger()
        self.logType = level
    }

    var defaultState: StateType {
        wrappedResolver.defaultState
    }

    func resolve(
        oldState: StateType,
        byApplying event: StateMachineEvent
    ) -> StateResolution<StateType> {

        let resolution = wrappedResolver.resolve(oldState: oldState, byApplying: event)

        os_log(logType, log: logger, .oldState, String(describing: oldState))
        os_log(logType, log: logger, .event, String(describing: event))
        os_log(logType, log: logger, .resolution, String(describing: resolution))

        return resolution
    }

}

extension StateMachineResolver {
    func logging(
        logger: OSLog? = nil,
        level: OSLogType = .debug
    ) -> LoggingStateMachineResolver<Self> {
        LoggingStateMachineResolver(
            resolver: self,
            logger: logger,
            level: level
        )
    }
}

private extension StaticString {
    #if DEBUG
    static let oldState: StaticString = "old state: %{public}@"
    static let event: StaticString = "event: %{public}@"
    static let resolution: StaticString = "resolution: %{public}@"
    #else
    static let oldState: StaticString = "old state: %{private}@"
    static let event: StaticString = "event: %{private}@"
    static let resolution: StaticString = "resolution: %{private}@"
    #endif
}
