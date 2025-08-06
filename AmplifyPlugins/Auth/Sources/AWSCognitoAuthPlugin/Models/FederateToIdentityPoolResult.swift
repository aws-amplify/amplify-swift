//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@preconcurrency import AWSPluginsCore
import Foundation

public struct FederateToIdentityPoolResult {

    public let credentials: AWSTemporaryCredentials

    public let identityId: String

}

extension FederateToIdentityPoolResult: Sendable { }
