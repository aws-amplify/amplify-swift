//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public typealias AuthChallengeDispositionHandler = (URLSession.AuthChallengeDisposition, URLCredential?) -> Void

extension AWSAPIPlugin: URLSessionDelegate {
    @objc public func urlSession(_ session: URLSession,
                                 didReceive challenge: URLAuthenticationChallenge,
                                 completionHandler: @escaping AuthChallengeDispositionHandler) {
        completionHandler(.performDefaultHandling, nil)
    }
}

extension AWSAPIPlugin: URLSessionTaskDelegate {

    @objc public func urlSession(_ session: URLSession,
                                 task: URLSessionTask,
                                 didReceive challenge: URLAuthenticationChallenge,
                                 completionHandler: @escaping AuthChallengeDispositionHandler) {
        completionHandler(.performDefaultHandling, nil)
    }

    @objc public func urlSession(_ session: URLSession,
                                 task: URLSessionTask,
                                 didCompleteWithError error: Error?) {
        urlSessionBehavior(session,
                           dataTaskBehavior: task,
                           didCompleteWithError: error)

    }

}

extension AWSAPIPlugin: URLSessionDataDelegate {
    //    func urlSession(_ session: URLSession,
    //                    dataTask: URLSessionDataTask,
    //                    didReceive response: URLResponse,
    //                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
    //        completionHandler(.allow)
    //    }

    @objc public func urlSession(_ session: URLSession,
                                 dataTask: URLSessionDataTask,
                                 didReceive data: Data) {
        urlSessionBehavior(session,
                           dataTaskBehavior: dataTask,
                           didReceive: data)
    }
}
