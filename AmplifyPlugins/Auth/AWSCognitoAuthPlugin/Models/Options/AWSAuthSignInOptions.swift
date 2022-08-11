//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct AWSAuthSignInOptions {

    public let authFlowType: AuthFlowType

    public let validationData: [String: String]?

    public let metadata: [String: String]?

    public init(validationData: [String: String]? = nil,
                metadata: [String: String]? = nil,
                authFlowType: AuthFlowType = .unknown) {
        self.validationData = validationData
        self.metadata = metadata
        self.authFlowType = authFlowType
    }
}

public enum AuthFlowType {

    case userSRP

    case custom

    case userPassword

    case unknown
}
