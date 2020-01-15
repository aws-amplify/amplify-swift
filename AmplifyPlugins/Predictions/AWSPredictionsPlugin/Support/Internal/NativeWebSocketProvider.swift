//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSTranscribeStreaming

class NativeWebSocketProvider: NSObject, AWSTranscribeStreamingWebSocketProvider, URLSessionWebSocketDelegate {
    //swiftlint:disable weak_delegate
    var clientDelegate: AWSTranscribeStreamingClientDelegate
    var webSocketTask: URLSessionWebSocketTask!
    var urlSession: URLSession!
    let delegateQueue = OperationQueue()
    var callbackQueue: DispatchQueue!
    private var pingTimer: Timer?

    override init() {
        self.clientDelegate = NativeWSTranscribeStreamingClientDelegate()
        super.init()
        self.urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: delegateQueue)

    }

    func configure(with urlRequest: URLRequest) {
        if let url = urlRequest.url {
        webSocketTask = urlSession.webSocketTask(with: url)
        }
    }

    func setDelegate(_ delegate: AWSTranscribeStreamingClientDelegate, dispatchQueue: DispatchQueue) {
        clientDelegate = delegate
        callbackQueue = dispatchQueue
    }

    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didOpenWithProtocol protocol: String?) {
        let status = AWSTranscribeStreamingClientConnectionStatus.connected

        callbackQueue.async {
            self.clientDelegate.connectionStatusDidChange(status, withError: nil)
        }
    }

    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
                    reason: Data?) {
        let status = AWSTranscribeStreamingClientConnectionStatus.closed
        let error = NSError(domain: AWSTranscribeStreamingClientErrorDomain, code: closeCode.rawValue, userInfo: nil)

        callbackQueue.async {
            self.clientDelegate.connectionStatusDidChange(status, withError: error)
        }
    }

    func connect() {
        // required to open socket
        webSocketTask.resume()
        listen()
    }

    func disconnect() {
        webSocketTask.cancel(with: .normalClosure, reason: nil)
        pingTimer?.invalidate()
    }

    func listen() {
        webSocketTask.receive { result in
            switch result {
            case .failure(let error):
               let status = AWSTranscribeStreamingClientConnectionStatus.closed

               self.callbackQueue.async {
                   self.clientDelegate.connectionStatusDidChange(status, withError: error)
               }
            case .success(let message):
                switch message {
                case .data(let data):
                    do {
                    let result = try AWSTranscribeStreamingEventDecoder.decodeEvent(data)
                        self.callbackQueue.async {
                            self.clientDelegate.didReceiveEvent(result, decodingError: nil)
                        }
                    } catch {
                        print(error)
                    }
                case .string:
                    break
                @unknown default:
                    fatalError()
                }
            }
            self.listen()
        }
    }

    func sendPing() {
        webSocketTask.sendPing { error in
            if let error = error {
                print("Sending PING failed: \(error)")
            }
            self.pingTimer = Timer.scheduledTimer(withTimeInterval: 25.0, repeats: true) { _ in
                self.sendPing()
            }
        }
    }

    func send(_ data: Data) {
        webSocketTask.send(URLSessionWebSocketTask.Message.data(data)) { error in
            if let error = error {
                do {
                    let result = try AWSTranscribeStreamingEventDecoder.decodeEvent(data)
                    self.callbackQueue.async {
                        self.clientDelegate.didReceiveEvent(result, decodingError: error)
                    }
                } catch {
                    self.callbackQueue.async {
                        self.clientDelegate.didReceiveEvent(nil, decodingError: error)
                    }
                }
            }
        }
    }
}

class NativeWSTranscribeStreamingClientDelegate: NSObject, AWSTranscribeStreamingClientDelegate {
    var receiveEventCallback: ((AWSTranscribeStreamingTranscriptResultStream?, Error?) -> Void)?
    var connectionStatusCallback: ((AWSTranscribeStreamingClientConnectionStatus, Error?) -> Void)?

    func didReceiveEvent(_ event: AWSTranscribeStreamingTranscriptResultStream?, decodingError: Error?) {
        receiveEventCallback?(event, decodingError)
    }

    func connectionStatusDidChange(_ connectionStatus: AWSTranscribeStreamingClientConnectionStatus,
                                   withError error: Error?) {
        connectionStatusCallback?(connectionStatus, error)
    }
}
