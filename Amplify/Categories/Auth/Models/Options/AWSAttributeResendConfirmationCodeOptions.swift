//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct AWSAttributeResendConfirmationCodeOptions {

    /// A map of custom key-value pairs that you can provide as input for any custom workflows that this action triggers.
    ///
    /// When you use the ResendConfirmationCode API action, Amazon Cognito invokes the function that is assigned to the custom message trigger.
    /// When Amazon Cognito invokes this function, it passes a JSON payload, which the function receives as input.
    /// This payload contains a clientMetadata attribute, which provides the data that you assigned to the ClientMetadata parameter in your GetUserAttributeVerificationCode request.
    /// In your function code in AWS Lambda, you can process the clientMetadata value to enhance your workflow for your specific needs.
    ///
    /// For more information, see Customizing user pool Workflows with Lambda Triggers in the Amazon Cognito Developer Guide.
    public let metadata: [String: String]?

    public init(metadata: [String: String]? = nil) {
        self.metadata = metadata
    }
}
