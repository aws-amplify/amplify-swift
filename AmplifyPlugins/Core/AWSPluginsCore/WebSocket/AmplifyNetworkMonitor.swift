//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine
import Network

/// - Note: `@unchecked Sendable` because both stored properties are `let` and each is safe to use
///   concurrently — `NWPathMonitor` delivers on its own queue, and `PassthroughSubject.send` is
///   safe from any thread. Neither type is declared `Sendable`, so the conformance cannot be
///   checked, and it must be stated here rather than in the protocol's extension.
@_spi(WebSocket)
public final class AmplifyNetworkMonitor: @unchecked Sendable {

    public enum State: Sendable {
        case none
        case online
        case offline
    }

    private let monitor: NWPathMonitor

    private let subject = PassthroughSubject<State, Never>()

    public var publisher: AnyPublisher<(State, State), Never> {
        subject.scan((.none, .none)) { previous, next in
            (previous.1, next)
        }.eraseToAnyPublisher()
    }

    public init(on interface: NWInterface.InterfaceType? = nil) {
        self.monitor = interface.map(NWPathMonitor.init(requiredInterfaceType:)) ?? NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            self?.subject.send(path.status == .satisfied ? .online : .offline)
        }

        monitor.start(queue: DispatchQueue(
            label: "com.amazonaws.amplify.ios.network.websocket.monitor",
            qos: .userInitiated
        ))

    }

    public func updateState(_ nextState: State) {
        subject.send(nextState)
    }

    deinit {
        subject.send(completion: .finished)
        monitor.cancel()
    }

}
