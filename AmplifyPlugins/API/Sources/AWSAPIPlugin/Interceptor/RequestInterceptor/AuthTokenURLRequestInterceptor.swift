//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Foundation

struct AuthTokenURLRequestInterceptor: URLRequestInterceptor {
    
    static let AWSDateISO8601DateFormat2 = "yyyyMMdd'T'HHmmss'Z'"
    
    private let userAgent = AmplifyAWSServiceConfiguration.userAgentLib
    let authTokenProvider: AuthTokenProvider

    init(authTokenProvider: AuthTokenProvider) {
        self.authTokenProvider = authTokenProvider
    }

    func intercept(_ request: URLRequest) async throws -> URLRequest {

        guard let mutableRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            throw APIError.unknown("Could not get mutable request", "")
        }
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = Self.AWSDateISO8601DateFormat2
        let amzDate = dateFormatter.string(from: date)

        mutableRequest.setValue(amzDate,
                                forHTTPHeaderField: URLRequestConstants.Header.xAmzDate)
        mutableRequest.addValue(userAgent,
                                forHTTPHeaderField: URLRequestConstants.Header.userAgent)
        
        let token: String
        do {
            token = try await authTokenProvider.getUserPoolAccessToken()
        } catch {
            throw APIError.operationError("Failed to retrieve authorization token.", "", error)
        }
        
        mutableRequest.setValue(token, forHTTPHeaderField: "authorization")
        return mutableRequest as URLRequest
    }
}
