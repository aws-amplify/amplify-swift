//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore

/// Concrete implementation of PreInitiateAuthSignUpBehavior
class AWSPreInitiateAuthSignUpBehavior : PreInitiateAuthSignUpBehavior {
    
    let urlSession: URLSession
    let userAgent: String
    
    init(urlSession: URLSession) {
        self.urlSession = urlSession
        self.userAgent = "\(AmplifyAWSServiceConfiguration.userAgentLib) \(AmplifyAWSServiceConfiguration.userAgentOS)"
    }
    
    func preInitiateAuthSignUp(preInitiateAuthSignUpEndpoint: URL,
                               preInitiateAuthSignUpPayload: PreInitiateAuthSignUpPayload) async throws -> Result<Void, AuthError> {
        
        var request = URLRequest(url: preInitiateAuthSignUpEndpoint)
        request.httpMethod = "POST"
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        
        do {
            let (_, response) = try await self.data(for: request)
            
            guard let response = response as? HTTPURLResponse else {
                throw AuthError.unknown("Response received is not a HTTPURLResponse")
            }
            
            if response.statusCode == 200 {
                return .successfulVoid
            } else {
                throw AuthError.unknown("Response received with status code: \(response.statusCode)")
            }
        } catch {
            throw AuthError.service(error.localizedDescription,
                                    "API Gateway returned an error. Please check the error message for more details.",
                                    error)
        }
    }
    
    private func data(
        for request: URLRequest,
        delegate: (URLSessionTaskDelegate)? = nil)
    async throws -> (Data, URLResponse) {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, *) {
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
}
