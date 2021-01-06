//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol AuthAttributeResendConfirmationCodeOperation: AmplifyOperation<
    AuthAttributeResendConfirmationCodeRequest,
    AuthCodeDeliveryDetails,
    AuthError
> {}

public extension HubPayload.EventName.Auth {

    /// eventName for HubPayloads emitted by this operation
    static let attributeResendConfirmationCodeAPI = "Auth.attributeResendConfirmationCodeAPI"
}
