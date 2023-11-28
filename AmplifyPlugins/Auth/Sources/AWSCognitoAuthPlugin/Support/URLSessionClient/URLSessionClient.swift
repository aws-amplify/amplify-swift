//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

// A delegate client for `URLSessionClientBehavior`
public struct URLSessionClient: URLSessionClientBehavior {

    let urlSession: URLSession
    
    public init(urlSession: URLSession) {
        self.urlSession = urlSession
    }
    
    public func cancelAndReset() async {
        self.urlSession.invalidateAndCancel()
        await self.urlSession.reset()
    }
    
    public func data(
        for request: URLRequest,
        delegate: (URLSessionTaskDelegate)?)
    async throws -> (Data, URLResponse) {
        if #available(iOS 15.0, *) {
            return try await self.urlSession.data(
                for: request,
                delegate: delegate
            )
        } else {
            // Fallback on earlier versions
            return try await withCheckedThrowingContinuation({ continuation in
                let dataTask = urlSession.dataTask(with: request) { data, response, error in
                    if let data = data, let response = response {
                        continuation.resume(returning: (data, response))
                    } else {
                        continuation.resume(throwing: error ?? AuthError.unknown(
                                    """
                                    An unknown error occurred with
                                    data: \(String(describing: data))
                                    response: \(String(describing: response))
                                    error: \(String(describing: error))
                                    """)
                        )
                    }
                }
                dataTask.resume()
            })
        }
    }
    
    public func data(
        from url: URL,
        delegate: (URLSessionTaskDelegate)?)
    async throws -> (Data, URLResponse) {
        if #available(iOS 15.0, *) {
            return try await self.urlSession.data(
                from: url,
                delegate: delegate
            )
        } else {
            // Fallback on earlier versions
            return try await withCheckedThrowingContinuation({ continuation in
                let dataTask = urlSession.dataTask(with: url) { data, response, error in
                    if let data = data, let response = response {
                        continuation.resume(returning: (data, response))
                    } else {
                        continuation.resume(throwing: error ?? AuthError.unknown(
                                    """
                                    An unknown error occurred with
                                    data: \(String(describing: data))
                                    response: \(String(describing: response))
                                    error: \(String(describing: error))
                                    """)
                        )
                    }
                }
                dataTask.resume()
            })
        }
    }
    
}
