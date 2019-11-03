//
// Copyright 2018-2019 Amazon.com,
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

    let userPoolTokenProvider: UserPoolTokenProvider

    init(userPoolTokenProvider: UserPoolTokenProvider) {
        self.userPoolTokenProvider = userPoolTokenProvider
    }

    func intercept(_ request: URLRequest) throws -> URLRequest {

        guard let mutableRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            throw APIError.unknown("Could not get mutable request", "")
        }

        mutableRequest.setValue(NSDate().aws_stringValue(AWSDateISO8601DateFormat2), forHTTPHeaderField: "X-Amz-Date")
        mutableRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        mutableRequest.setValue("aws-sdk-ios/2.15.0 Amplify", forHTTPHeaderField: "User-Agent")

        let tokenResult = userPoolTokenProvider.getToken()
        guard case let .success(token) = tokenResult else {
            if case let .failure(error) = tokenResult {
                throw APIError.operationError("Got error trying to get token", "", error)
            }

            return mutableRequest as URLRequest
        }
        mutableRequest.setValue(token, forHTTPHeaderField: "authorization")
        return mutableRequest as URLRequest
    }
}
