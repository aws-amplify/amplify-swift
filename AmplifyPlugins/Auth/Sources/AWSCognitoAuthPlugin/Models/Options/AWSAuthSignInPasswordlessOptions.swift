//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Foundation

public struct AWSAuthSignInPasswordlessOptions {

    public let clientMetadata: [String: String]?

    public init(clientMetadata: [String: String]? = nil) {
        self.clientMetadata = clientMetadata
    }

}
