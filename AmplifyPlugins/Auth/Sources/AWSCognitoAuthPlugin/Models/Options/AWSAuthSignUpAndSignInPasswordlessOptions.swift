//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Foundation

public struct AWSAuthSignUpAndSignInPasswordlessOptions {

    public let userAttributes: [String: String]?
    public let clientMetadata: [String: String]?

    public init(userAttributes: [String: String]? = nil,
                clientMetadata: [String: String]? = nil) {
        self.userAttributes = userAttributes
        self.clientMetadata = clientMetadata
    }

}
