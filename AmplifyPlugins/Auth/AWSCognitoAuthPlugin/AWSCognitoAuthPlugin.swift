//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
#if COCOAPODS
import AWSMobileClient
#else
import AWSMobileClientXCF
#endif

/// Auth plugin that uses AWS Cognito UserPool and IdentityPool.
///
/// The implicitly unwrapped optionals in this class are assigned in the `configure` method in
/// `AWSCognitoAuthPlugin+Configure` extension. Make sure to call `Amplify.configure` after adding the
/// plugin to `Amplify`.
final public class AWSCognitoAuthPlugin: AuthCategoryPlugin {

    /// A queue that regulates the execution of operations.
    var queue: OperationQueue!

    /// Operations related to the authentication provider.
    var authenticationProvider: AuthenticationProviderBehavior!

    /// Operations related to the authorization provider
    var authorizationProvider: AuthorizationProviderBehavior!

    /// Operations related to the user operations provider
    var userService: AuthUserServiceBehavior!

    /// Operations related to the auth device
    var deviceService: AuthDeviceServiceBehavior!

    /// Handles different auth event send through hub
    var hubEventHandler: AuthHubEventBehavior!

    /// Auth configuration used during initialization
    var configuration: JSONValue!

    /// The unique key of the plugin within the auth category.
    public var key: PluginKey {
        return "awsCognitoAuthPlugin"
    }

    /// The user network preferences for timeout and retry
    let networkPreferences: AWSCognitoNetworkPreferences?

    public func getEscapeHatch() -> AWSCognitoAuthService {
        if let internalAuthorizationProvider = authorizationProvider as? AuthorizationProviderAdapter,
            let awsMobileClientProvider = internalAuthorizationProvider.awsMobileClient as? AWSMobileClientAdapter {
            return .awsMobileClient(awsMobileClientProvider.awsMobileClient)
        }
        fatalError("Invoke Amplify configuration before accessing escape hatch")
    }

    /// Instantiates an instance of the AWSCognitoAuthPlugin.
    public init() {
        self.networkPreferences = nil
    }

    /// Instantiates an instance of the AWSCognitoAuthPlugin with custom network preferences
    /// - Parameters:
    ///   - networkPreferences: network preferences
    public init(networkPreferences: AWSCognitoNetworkPreferences) {
        self.networkPreferences = networkPreferences
    }
}

extension AWSCognitoAuthPlugin: AmplifyVersionable { }
