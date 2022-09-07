//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Amplify

protocol AuthResendSignUpCodeTask: AmplifyAuthTask where Request == AuthResendSignUpCodeRequest, Success == AuthCodeDeliveryDetails, Failure == AuthError {}

public extension HubPayload.EventName.Auth {

    /// eventName for HubPayloads emitted by this operation
    static let resendSignUpCodeAPI = "Auth.resendSignUpCodeAPI"
}
