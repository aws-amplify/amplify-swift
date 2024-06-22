//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Network
import Combine

@_spi(WebSocket)
public final class AmplifyNetworkMonitor {

    public enum State {
        case none
        case online
        case offline
    }

    private let monitor: NWPathMonitor
    private var pingMonitor: AnyCancellable?

    private let subject = PassthroughSubject<State, Never>()

    public var publisher: AnyPublisher<(State, State), Never> {
        subject.scan((.none, .none)) { previous, next in
            (previous.1, next)
        }.eraseToAnyPublisher()
    }

    public init(on interface: NWInterface.InterfaceType? = nil) {
        monitor = interface.map(NWPathMonitor.init(requiredInterfaceType:)) ?? NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            self?.subject.send(path.status == .satisfied ? .online : .offline)
        }

        monitor.start(queue: DispatchQueue(
            label: "com.amazonaws.amplify.ios.network.websocket.monitor",
            qos: .userInitiated
        ))

        pingMonitor = startPingMonitor()
    }

    public func updateState(_ nextState: State) {
        subject.send(nextState)
    }

    deinit {
        subject.send(completion: .finished)
        pingMonitor?.cancel()
        monitor.cancel()
    }

    private func pingCloudflare() -> Future<State, Never> {
        Future { promise in
            let oneDNS = URL(string: "https://one.one.one.one")!
            var request = URLRequest(url: oneDNS)
            request.httpMethod = "HEAD"
            request.timeoutInterval = .seconds(3)

            URLSession.shared.dataTask(with: request) { _, response, error in
                if let error {
                    promise(.success(State.offline))
                } else if let httpResponse = response as? HTTPURLResponse {
                    promise(.success(httpResponse.statusCode == 200 ? State.online : State.offline))
                }
            }.resume()
        }
    }

    private func startPingMonitor() -> AnyCancellable {
        return Timer.TimerPublisher(interval: .seconds(3), runLoop: .main, mode: .common)
            .autoconnect()
            .receive(on: DispatchQueue.global(qos: .default))
            .compactMap { [weak self] _ in self?.pingCloudflare() }
            .flatMap { $0 }
            .sink { [weak self] state in
                self?.updateState(state)
            }
    }
}
