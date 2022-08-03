//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore

class AuthRecorderInterceptor: URLRequestInterceptor {
    let awsAuthService: AWSAuthService = AWSAuthService()
    var consumedAuthTypes: Set<AWSAuthorizationType> = []
    private let accessQueue = DispatchQueue(label: "com.amazon.AuthRecorderInterceptor.consumedAuthTypes")

    private func recordAuthType(_ authType: AWSAuthorizationType) {
        accessQueue.async {
            self.consumedAuthTypes.insert(authType)
        }
    }

    func intercept(_ request: URLRequest) throws -> URLRequest {
        guard let headers = request.allHTTPHeaderFields else {
            fatalError("No headers found in request \(request)")
        }

        let authHeaderValue = headers["Authorization"]
        let apiKeyHeaderValue = headers["x-api-key"]

        if apiKeyHeaderValue != nil {
            recordAuthType(.apiKey)
        }

        if let authHeaderValue = authHeaderValue,
           case let .success(claims) = awsAuthService.getTokenClaims(tokenString: authHeaderValue),
           let cognitoIss = claims["iss"] as? String, cognitoIss.contains("cognito") {
            recordAuthType(.amazonCognitoUserPools)
        }

        if let authHeaderValue = authHeaderValue,
           authHeaderValue.starts(with: "AWS4-HMAC-SHA256") {
            recordAuthType(.awsIAM)
        }

        return request
    }

    func reset() {
        consumedAuthTypes = []
    }
}
