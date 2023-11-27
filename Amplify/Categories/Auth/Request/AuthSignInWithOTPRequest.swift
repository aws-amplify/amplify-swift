//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Request to sign in a user with Passwordless OTP flow
public struct AuthSignInWithOTPRequest: AmplifyOperationRequest {

    /// User name for which the passwordless OTP  was initiated
    public let username: String

    /// The flow that the request should begin with.
    public let flow: AuthPasswordlessFlow

    /// The destination where the OTP will be sent
    public let destination: AuthPasswordlessDeliveryDestination

    /// Extra request options defined in `AuthSignInWithOTPRequest.Options`
    public var options: Options

    public init(username: String, 
         flow: AuthPasswordlessFlow,
         destination: AuthPasswordlessDeliveryDestination,
         options: Options) {
        self.username = username
        self.flow = flow
        self.destination = destination
        self.options = options
    }
}

public extension AuthSignInWithOTPRequest {

    struct Options {

        /// Extra plugin specific options, only used in special circumstances when the existing options do not provide
        /// a way to utilize the underlying auth plugin functionality. See plugin documentation for expected
        /// key/values
        public let pluginOptions: Any?

        public init(pluginOptions: Any? = nil) {
            self.pluginOptions = pluginOptions
        }
    }
}
