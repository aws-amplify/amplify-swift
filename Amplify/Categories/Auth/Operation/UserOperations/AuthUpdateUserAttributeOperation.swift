//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol AuthUpdateUserAttributeOperation: AmplifyOperation<
    AuthUpdateUserAttributeRequest,
    AuthUpdateAttributeResult,
    AuthError
> {}

public extension HubPayload.EventName.Auth {

    /// eventName for HubPayloads emitted by this operation
    static let updateUserAttributeAPI = "Auth.updateUserAttributeAPI"
}
