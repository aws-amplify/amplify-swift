//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

struct PasswordlessSignUpHelper: DefaultLogger {

    private let authEnvironment: AuthEnvironment
    private let authConfiguration: AuthConfiguration?
    private let username: String
    private let signInRequestMetadata: PasswordlessCustomAuthRequest
    private let pluginOptions: Any?

    init(configuration: AuthConfiguration?,
         authEnvironment: AuthEnvironment,
         username: String,
         signInRequestMetadata: PasswordlessCustomAuthRequest,
         pluginOptions: Any?) {
        self.authConfiguration = configuration
        self.authEnvironment = authEnvironment
        self.username = username
        self.signInRequestMetadata = signInRequestMetadata
        self.pluginOptions = pluginOptions
    }

    func signUp() async -> Result<Void, AuthError> {
        log.verbose("Starting execution")
        // Check if we have a user pool configuration
        // User pool configuration is used retrieve API Gateway information,
        // so that sign up flow can take place
        guard let userPoolConfiguration = authConfiguration?.getUserPoolConfiguration() else {
            let message = AuthPluginErrorConstants.configurationError
            let authError = AuthError.configuration(
                "Could not find user pool configuration",
                message)
            return .failure(authError)
        }

        guard let authPasswordlessClient = authEnvironment.authPasswordlessClient else {
            let message = AuthPluginErrorConstants.configurationError
            let authError = AuthError.configuration(
                "URL Session client is not set up",
                message)
            return .failure(authError)
        }
        
        guard let endpoint = userPoolConfiguration.passwordlessSignUpEndpoint else {
            let message = AuthPluginErrorConstants.configurationError
            let authError = AuthError.configuration(
                "API Gateway endpoint not found in configuration",
                message)
            return .failure(authError)
        }
        
        guard let endpointURL = URL(string: endpoint) else {
            let message = AuthPluginErrorConstants.configurationError
            let authError = AuthError.configuration(
                "API Gateway URL is not valid",
                message)
            return .failure(authError)
        }
        
        guard let deliveryMedium = signInRequestMetadata.deliveryMedium else {
            let message = AuthPluginErrorConstants.configurationError
            let authError = AuthError.configuration(
                "Delivery medium is not specified",
                message)
            return .failure(authError)
        }
        
        var userAttributes : [String:String] = [:]
        if let pluginOptions = pluginOptions as? AWSAuthSignUpAndSignInPasswordlessOptions,
           let attributes = pluginOptions.userAttributes {
            userAttributes = attributes
        }
        
        let payload = PreInitiateAuthSignUpPayload(username: username,
                                                   deliveryMedium: deliveryMedium.rawValue,
                                                   userAttributes: userAttributes,
                                                   userPoolId: userPoolConfiguration.poolId,
                                                   region: userPoolConfiguration.region)
        return await authPasswordlessClient.preInitiateAuthSignUp(endpoint: endpointURL,
                                                                  payload: payload)
    }
    
}
