//
// Copyright 2018-2021 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public protocol AuthConfirmSignUpOperation: AmplifyOperation<AuthConfirmSignUpRequest, AuthSignUpResult, AuthError> {}

public extension HubPayload.EventName.Auth {

    /// eventName for HubPayloads emitted by this operation
    static let confirmSignUpAPI = "Auth.confirmSignUpAPI"
}
