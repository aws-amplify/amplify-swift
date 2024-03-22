//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Foundation
import Network

class LocalWebSocketServer {
    let portNumber = UInt16.random(in: 49152..<65535)
    var connections = [NWConnection]()

    var listener: NWListener?

    private static func recursiveRead(_ connection: NWConnection) {
        connection.receiveMessage { content, contentContext, _, error in
            if let error {
                print("Connection failed to receive message, error: \(error)")
                return
            }

            if let content, let contentContext {
                connection.send(content: content, contentContext: contentContext, completion: .idempotent)
            }

            recursiveRead(connection)
        }
    }

    func start() throws -> URL  {
        let params = NWParameters.tcp
        let stack = params.defaultProtocolStack
        let ws = NWProtocolWebSocket.Options(.version13)
        stack.applicationProtocols.insert(ws, at: 0)
        let port = NWEndpoint.Port(rawValue: portNumber)!
        guard let listener = try? NWListener(using: params, on: port) else {
            throw "unable to start the listener at: localhost:\(port)"
        }

        listener.newConnectionHandler = { [weak self] conn in
            self?.connections.append(conn)
            conn.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    print("Connection is ready")
                case .setup:
                    print("Connection is setup")
                case .preparing:
                    print("Connection is preparing")
                case .waiting(let error):
                    print("Connection is waiting with error: \(error)")
                case .failed(let error):
                    print("Connection failed with error \(error)")
                case .cancelled:
                    print("Connection is cancelled")
                @unknown default:
                    print("Connection is in unknown state -> \(state)")
                }
            }
            conn.start(queue: DispatchQueue.global(qos: .userInitiated))
            Self.recursiveRead(conn)
        }

        listener.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("Socket is ready")
            case .setup:
                print("Socket is setup")
            case .cancelled:
                print("Socket is cancelled")
            case .failed(let error):
                print("Socket failed with error: \(error)")
            case .waiting(let error):
                print("Socket in waiting state with error: \(error)")
            @unknown default:
                print("Socket in unkown state -> \(state)")
                break
            }
        }

        listener.start(queue: DispatchQueue.global(qos: .userInitiated))
        self.listener = listener
        return URL(string: "http://localhost:\(portNumber)")!
    }

    func stop() {
        self.listener?.cancel()
    }

    func sendTransientFailureToConnections() {
        self.connections.forEach {
            var metadata = NWProtocolWebSocket.Metadata(opcode: .close)
            metadata.closeCode = .protocolCode(NWProtocolWebSocket.CloseCode.Defined.internalServerError)
            $0.send(
                content: nil,
                contentContext: NWConnection.ContentContext(identifier: "WebSocket", metadata: [metadata]),
                completion: .idempotent
            )
        }
    }
}
