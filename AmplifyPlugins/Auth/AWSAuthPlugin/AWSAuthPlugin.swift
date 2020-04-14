//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSMobileClient

final public class AWSAuthPlugin: AuthCategoryPlugin {

    /// A queue that regulates the execution of operations.
    var queue: OperationQueue!

    /// Operations related to the authentication provider.
    var authenticationProvider: AuthenticationProviderBehavior!

    /// Operations related to the authorization provider
    var authorizationProvider: AuthorizationProviderBehavior!

    /// The unique key of the plugin within the auth category.
    public var key: PluginKey {
        return AuthPluginConstants.awsAuthPluginKey
    }

    /// Instantiates an instance of the AWSAuthPlugin.
    public init() {
    }
}
