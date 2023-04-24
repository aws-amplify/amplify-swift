//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Foundation
import AWSCore

struct AuthTokenURLRequestInterceptor: URLRequestInterceptor {

    let authTokenProvider: AuthTokenProvider

    init(authTokenProvider: AuthTokenProvider) {
        self.authTokenProvider = authTokenProvider
    }

    func intercept(_ request: URLRequest) throws -> URLRequest {

        guard let mutableRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            throw APIError.unknown("Could not get mutable request", "")
        }
        mutableRequest.setValue(NSDate().aws_stringValue(AWSDateISO8601DateFormat2),
                                forHTTPHeaderField: URLRequestConstants.Header.xAmzDate)
        mutableRequest.setValue(URLRequestConstants.ContentType.applicationJson,
                                forHTTPHeaderField: URLRequestConstants.Header.contentType)
        mutableRequest.setValue(AmplifyAWSServiceConfiguration.baseUserAgent(),
                                forHTTPHeaderField: URLRequestConstants.Header.userAgent)

        let tokenResult = authTokenProvider.getToken()
        guard case let .success(token) = tokenResult else {
            if case let .failure(error) = tokenResult {
                throw APIError.operationError("Failed to retrieve authorization token.", "", error)
            }

            return mutableRequest as URLRequest
        }
        mutableRequest.setValue(token, forHTTPHeaderField: "authorization")
        return mutableRequest as URLRequest
    }

    func intercept(_ request: URLRequest, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        guard let mutableRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            completion(.failure(APIError.unknown("Could not get mutable request", "")))
            return
        }

        authTokenProvider.getToken { result in
            do {
                let token = try result.get()
                mutableRequest.setValue(NSDate().aws_stringValue(AWSDateISO8601DateFormat2),
                                        forHTTPHeaderField: URLRequestConstants.Header.xAmzDate)
                mutableRequest.setValue(URLRequestConstants.ContentType.applicationJson,
                                        forHTTPHeaderField: URLRequestConstants.Header.contentType)
                mutableRequest.setValue(AmplifyAWSServiceConfiguration.baseUserAgent(),
                                        forHTTPHeaderField: URLRequestConstants.Header.userAgent)
                mutableRequest.setValue(token, forHTTPHeaderField: "authorization")
                completion(.success(mutableRequest as URLRequest))
                return
            } catch {
                let apiError = APIError.operationError("Failed to retrieve authorization token.", "", error)
                completion(.failure(apiError))
            }
        }
    }
}
