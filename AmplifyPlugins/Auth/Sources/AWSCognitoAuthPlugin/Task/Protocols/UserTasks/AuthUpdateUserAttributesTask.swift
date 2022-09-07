//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Amplify

protocol AuthUpdateUserAttributesTask: AmplifyAuthTask where Request == AuthUpdateUserAttributesRequest, Success == [AuthUserAttributeKey: AuthUpdateAttributeResult], Failure == AuthError {}

public extension HubPayload.EventName.Auth {

    /// eventName for HubPayloads emitted by this operation
    static let updateUserAttributesAPI = "Auth.updateUserAttributesAPI"
}
