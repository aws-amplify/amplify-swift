//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Foundation
import AWSCognitoIdentityProvider

public struct AWSAuthSignInOptions {

    public let authFlowType: AuthFlowType?

    /// You can pass data to your Lambda function using validation data during sign in
    public let validationData: [String: String]?

    public let metadata: [String: String]?

    public init(validationData: [String: String]? = nil,
                metadata: [String: String]? = nil,
                authFlowType: AuthFlowType? = nil) {
        self.validationData = validationData
        self.metadata = metadata
        self.authFlowType = authFlowType
    }
}
