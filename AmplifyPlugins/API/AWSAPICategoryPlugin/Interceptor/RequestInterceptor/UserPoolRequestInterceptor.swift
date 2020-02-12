//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Foundation
import AWSCore
import AWSMobileClient

struct UserPoolURLRequestInterceptor: URLRequestInterceptor {

    let userPoolTokenProvider: AuthTokenProvider

    init(userPoolTokenProvider: AuthTokenProvider) {
        self.userPoolTokenProvider = userPoolTokenProvider
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

        let tokenResult = userPoolTokenProvider.getToken()
        guard case let .success(token) = tokenResult else {
            if case let .failure(error) = tokenResult {
                throw APIError.operationError("Failed to retrieve Cognito UserPool token.", "", error)
            }

            return mutableRequest as URLRequest
        }
        mutableRequest.setValue(token, forHTTPHeaderField: "authorization")
        return mutableRequest as URLRequest
    }
}
