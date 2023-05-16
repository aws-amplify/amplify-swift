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

    public let metadata: [String: String]?

    public init(
        metadata: [String: String]? = nil,
        authFlowType: AuthFlowType? = nil
    ) {
        self.metadata = metadata
        self.authFlowType = authFlowType
    }

    /// You can pass data to your Lambda function using validation data during sign in
    @available(*, deprecated, renamed: "metadata")
    public var validationData: [String: String]?

    @available(*, deprecated, renamed: "init(metadata:authFlowType:)")
    public init(validationData: [String: String]? = nil,
                metadata: [String: String]? = nil,
                authFlowType: AuthFlowType? = nil) {
        self.validationData = validationData
        self.metadata = metadata
        self.authFlowType = authFlowType
    }
}
