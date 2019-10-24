//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

/// An HTTPTransport backed by a URLSession
final class URLSessionHTTPTransport: HTTPTransport {
    var sessionConfig: URLSessionConfiguration!
    var session: URLSession!

    weak var delegate: HTTPTransportTaskDelegate? {
        get {
            session?.delegate as? HTTPTransportTaskDelegate
        }

        // swiftlint:disable unused_setter_value
        set {
            // URLSession.delegate is read-only
        }
        // swiftlint:enable unused_setter_value
    }

    init(delegate: URLSessionTaskDelegate) {
        self.delegate = delegate as? HTTPTransportTaskDelegate
        self.sessionConfig = URLSessionConfiguration.default
        self.session = URLSession(configuration: sessionConfig,
                                  delegate: delegate,
                                  delegateQueue: nil)
    }

    func task(for request: URLRequest) -> HTTPTransportTask {
        let task = session.dataTask(with: request)
        return task
    }

    func reset(onComplete: BasicClosure?) {
        session.invalidateAndCancel()
        session.reset {
            self.session = nil
            onComplete?()
        }
    }

}

extension URLSessionDataTask: HTTPTransportTask {
    public func pause() {
        suspend()
    }
}

extension AWSAPICategoryPlugin: URLSessionTaskDelegate {
    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           didCompleteWithError error: Error?) {
        print(#function)
    }

    public func urlSession(_ session: URLSession,
                           dataTask: URLSessionDataTask,
                           didReceive data: Data) {
        task(dataTask, didReceiveData: data)
    }

    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        print(#function)
    }

    public func urlSession(_ session: URLSession,
                           didBecomeInvalidWithError error: Error?) {
        print(#function)
    }

    public func urlSession(_ session: URLSession,
                           taskIsWaitingForConnectivity task: URLSessionTask) {
        print(#function)
    }

    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           didFinishCollecting metrics: URLSessionTaskMetrics) {
        print(#function)
    }

    public func urlSession(_ session: URLSession,
                           didReceive challenge: URLAuthenticationChallenge,
                           completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        print(#function)
    }

    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        print(#function)
    }

    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           willBeginDelayedRequest request: URLRequest,
                           completionHandler: @escaping (URLSession.DelayedRequestDisposition, URLRequest?) -> Void) {
        print(#function)
    }

    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           didSendBodyData bytesSent: Int64,
                           totalBytesSent: Int64,
                           totalBytesExpectedToSend: Int64) {
        print(#function)
    }

    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           didReceive challenge: URLAuthenticationChallenge,
                           completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        print(#function)
    }

    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           willPerformHTTPRedirection response: HTTPURLResponse,
                           newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        print(#function)
    }
}
