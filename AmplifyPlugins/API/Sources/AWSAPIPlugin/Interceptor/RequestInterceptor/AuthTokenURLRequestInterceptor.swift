//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import InternalAmplifyCredentials
import Foundation

struct AuthTokenURLRequestInterceptor: URLRequestInterceptor {

    static let AWSDateISO8601DateFormat2 = "yyyyMMdd'T'HHmmss'Z'"

    private let userAgent = AmplifyAWSServiceConfiguration.userAgentLib
    let authTokenProvider: AuthTokenProvider
    let isTokenExpired: ((String) -> Bool)?

    init(authTokenProvider: AuthTokenProvider, 
         isTokenExpired: ((String) -> Bool)? = nil) {
        self.authTokenProvider = authTokenProvider
        self.isTokenExpired = isTokenExpired
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
        
        if isTokenExpired?(token) ?? false {
            // If the access token has expired, we send back the underlying "AuthError.sessionExpired" error.
            // Without a more specific AuthError case like "tokenExpired", this is the closest representation.
            throw APIError.operationError("Auth Token Provider returned a expired token.",
                                          "Please call `Amplify.Auth.fetchAuthSession()` or sign in again.",
                                          AuthError.sessionExpired("", "", nil))
        }

        mutableRequest.setValue(token, forHTTPHeaderField: "authorization")
        return mutableRequest as URLRequest
    }
}
