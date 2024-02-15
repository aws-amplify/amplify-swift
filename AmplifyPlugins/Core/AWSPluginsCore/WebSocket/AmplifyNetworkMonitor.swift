//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Network
import Combine

@_spi(AmplifySwift)
public final class AmplifyNetworkMonitor {

    public enum State {
        case none
        case online
        case offline
    }

    #if DEBUG
    private let monitor = NWPathMonitor(requiredInterfaceType: .cellular)
    #else
    private let monitor = NWPathMonitor()
    #endif

    private let subject = PassthroughSubject<State, Never>()

    public var publisher: AnyPublisher<(State, State), Never> {
        subject.scan((.none, .none)) { previous, next in
            (previous.1, next)
        }.eraseToAnyPublisher()
    }

    public init() {

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
