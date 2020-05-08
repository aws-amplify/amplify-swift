//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol AuthUpdateUserAttributeOperation: AmplifyOperation<AuthUpdateUserAttributeRequest,
    Void,
    AuthUpdateAttributeResult,
AmplifyAuthError> {}

public extension HubPayload.EventName.Auth {

    /// eventName for HubPayloads emitted by this operation
    static let updateUserAttribute = "Auth.updateUserAttribute"
}
