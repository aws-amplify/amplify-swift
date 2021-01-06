//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol AuthFetchUserAttributeOperation: AmplifyOperation<
    AuthFetchUserAttributesRequest,
    [AuthUserAttribute],
    AuthError
> {}

public extension HubPayload.EventName.Auth {

    /// eventName for HubPayloads emitted by this operation
    static let fetchUserAttributesAPI = "Auth.fetchUserAttributesAPI"
}
