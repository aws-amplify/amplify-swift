//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

// swiftlint:disable:next line_length
protocol AuthSendUserAttributeVerificationCodeTask: AmplifyAuthTask where Request == AuthSendUserAttributeVerificationCodeRequest, Success == AuthCodeDeliveryDetails, Failure == AuthError {}

public extension HubPayload.EventName.Auth {

    /// eventName for HubPayloads emitted by this operation
    static let sendUserAttributeVerificationCodeAPI = "Auth.sendUserAttributeVerificationCodeAPI"
}
