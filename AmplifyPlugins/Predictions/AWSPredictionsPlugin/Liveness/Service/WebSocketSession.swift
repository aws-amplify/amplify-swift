//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

final class WebSocketSession {
    private let urlSessionWebSocketDelegate: Delegate
    private let session: URLSession
    private var task: URLSessionWebSocketTask?
    private var receiveMessage: ((Result<URLSessionWebSocketTask.Message, Error>) -> WebSocketMessageResult)?
    private var onSocketClosed: ((URLSessionWebSocketTask.CloseCode) -> Void)?
    private var onServerDateReceived: ((Date?) -> Void)?
    private let delegateQueue: OperationQueue

    init() {
        self.delegateQueue = OperationQueue()
        self.delegateQueue.maxConcurrentOperationCount = 1
        self.delegateQueue.qualityOfService = .userInteractive
        
        self.urlSessionWebSocketDelegate = Delegate()

        self.session = URLSession(
            configuration: .default,
            delegate: urlSessionWebSocketDelegate,
            delegateQueue: delegateQueue
        )
    }

    func onMessageReceived(_ receive: @escaping (Result<URLSessionWebSocketTask.Message, Error>) -> WebSocketMessageResult) {
        self.receiveMessage = receive
    }

    func onSocketClosed(_ onClose: @escaping (URLSessionWebSocketTask.CloseCode) -> Void) {
        urlSessionWebSocketDelegate.onClose = onClose
    }

    func onSocketOpened(_ onOpen: @escaping () -> Void) {
        urlSessionWebSocketDelegate.onOpen = onOpen
    }
    
    func onServerDateReceived(_ onServerDateReceived: @escaping (Date?) -> Void) {
        urlSessionWebSocketDelegate.onServerDateReceived = onServerDateReceived
    }

    func receive(result: WebSocketMessageResult) {
        switch result {
        case .continueToReceive:
            task?.receive(completionHandler: { [weak self] result in
                if let webSocketResult = self?.receiveMessage?(result) {
                    self?.receive(result: webSocketResult)
                }
            })
        case .stopAndInvalidateSession:
            session.finishTasksAndInvalidate()
        case .invalidateSessionAndRetry(let url):
            session.finishTasksAndInvalidate()
            open(url: url)
        }
    }

    func open(url: URL) {
        var request = URLRequest(url: url)
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")
        task = session.webSocketTask(with: request)
        receive(result: .continueToReceive)
        task?.resume()
    }

    func close(with code: URLSessionWebSocketTask.CloseCode?, reason: Data? = nil) {
        if let code {
            task?.cancel(with: code, reason: reason)
        } else {
            task?.cancel()
        }
    }

    func send(
        message: URLSessionWebSocketTask.Message,
        onError: @escaping (Error) -> Void
    ) {
        task?.send(
            message,
            completionHandler: { error in
                guard let error else { return }
                onError(error)
            }
        )
    }

    final class Delegate: NSObject, URLSessionWebSocketDelegate, URLSessionTaskDelegate {
        var onClose: (URLSessionWebSocketTask.CloseCode) -> Void = { _ in }
        var onOpen: () -> Void = {}
        var onServerDateReceived: (Date?) -> Void = { _ in }

        // MARK: - URLSessionWebSocketDelegate methods
        func urlSession(
            _ session: URLSession,
            webSocketTask: URLSessionWebSocketTask,
            didOpenWithProtocol protocol: String?
        ) {
            onOpen()
        }

        func urlSession(
            _ session: URLSession,
            webSocketTask: URLSessionWebSocketTask,
            didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
            reason: Data?
        ) {
            onClose(closeCode)
        }
        
        // MARK: - URLSessionTaskDelegate methods
        func urlSession(_ session: URLSession,
                        task: URLSessionTask,
                        didFinishCollecting metrics: URLSessionTaskMetrics
        ) {
            guard let httpResponse = metrics.transactionMetrics.first?.response as? HTTPURLResponse,
                  let dateString = httpResponse.value(forHTTPHeaderField: "Date") else {
                Amplify.log.verbose("\(#function): Couldn't find Date header in URLSession metrics")
                onServerDateReceived(nil)
                return
            }
            
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.dateFormat = "EEE, d MMM yyyy HH:mm:ss z"
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            guard let serverDate = dateFormatter.date(from: dateString) else {
                Amplify.log.verbose("\(#function): Error parsing Date header in expected format")
                onServerDateReceived(nil)
                return
            }
            
            onServerDateReceived(serverDate)
        }
    }
    
    enum WebSocketMessageResult {
        case continueToReceive
        case stopAndInvalidateSession
        case invalidateSessionAndRetry(url: URL)
    }
}
