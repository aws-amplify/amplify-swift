//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

final class WebSocketSession {
    private let urlSessionWebSocketDelegate: Delegate
    private let session: URLSession
    private var task: URLSessionWebSocketTask?
    private var receiveMessage: ((Result<URLSessionWebSocketTask.Message, Error>) -> Bool)?
    private var onSocketClosed: ((URLSessionWebSocketTask.CloseCode) -> Void)?

    init() {
        self.urlSessionWebSocketDelegate = Delegate()
        self.session = URLSession(
            configuration: .default,
            delegate: urlSessionWebSocketDelegate,
            delegateQueue: .init()
        )
    }

    func onMessageReceived(_ receive: @escaping (Result<URLSessionWebSocketTask.Message, Error>) -> Bool) {
        self.receiveMessage = receive
    }

    func onSocketClosed(_ onClose: @escaping (URLSessionWebSocketTask.CloseCode) -> Void) {
        urlSessionWebSocketDelegate.onClose = onClose
    }

    func onSocketOpened(_ onOpen: @escaping () -> Void) {
        urlSessionWebSocketDelegate.onOpen = onOpen
    }

    func receive(shouldContinue: Bool) {
        guard shouldContinue else {
            session.finishTasksAndInvalidate()
            return
        }

        task?.receive(completionHandler: { [weak self] result in
            if let shouldContinue = self?.receiveMessage?(result) {
                self?.receive(shouldContinue: shouldContinue)
            }
        })
    }

    func open(url: URL) {
        var request = URLRequest(url: url)
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")
        task = session.webSocketTask(with: request)
        receive(shouldContinue: true)
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

    final class Delegate: NSObject, URLSessionWebSocketDelegate {
        var onClose: (URLSessionWebSocketTask.CloseCode) -> Void = { _ in }
        var onOpen: () -> Void = {}

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
    }
}
