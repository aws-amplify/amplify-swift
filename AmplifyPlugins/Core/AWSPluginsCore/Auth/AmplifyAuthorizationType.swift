//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Foundation

public enum AmplifyAuthorizationType {
    case inferred
    case designated(AWSAuthorizationType)

    public var awsAuthType: AWSAuthorizationType? {
        switch self {
        case .inferred: return nil
        case .designated(let authType): return authType
        }
    }
}

extension AmplifyAuthorizationType: Equatable { }
