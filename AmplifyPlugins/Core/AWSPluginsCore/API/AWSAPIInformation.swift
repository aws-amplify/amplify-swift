//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// API plugin information
public protocol AWSAPIInformation {

    /// Returns the deafult auth type from the default endpoint.
    func defaultAuthType() throws -> AWSAuthorizationType

    /// Returns the default auth type on endpoint specified by `apiName`
    func defaultAuthType(for apiName: String?) throws -> AWSAuthorizationType
}
