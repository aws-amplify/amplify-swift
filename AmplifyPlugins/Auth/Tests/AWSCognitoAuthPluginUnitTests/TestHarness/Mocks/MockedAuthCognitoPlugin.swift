//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import AWSCognitoIdentity
import AWSCognitoIdentityProvider
import AWSPluginsCore
import ClientRuntime

@testable import Amplify
@testable import AWSCognitoAuthPlugin

struct MockedAuthCognitoPluginHelper {

    let authConfiguration: AuthConfiguration
    let initialAuthState: AuthState
    let mockIdentityProvider: MockIdentityProvider
    let mockIdentity: MockIdentity

    func createPlugin() -> AWSCognitoAuthPlugin {

        let authResolver = AuthState.Resolver().eraseToAnyResolver()
        let authEnvironment = makeAuthEnvironment(authConfiguration: authConfiguration)

        let credentialStoreResolver = CredentialStoreState.Resolver().eraseToAnyResolver()
        let credentialEnvironment = credentialStoreEnvironment(authConfiguration: authConfiguration)

        let authStateMachine = StateMachine(
            resolver: authResolver,
            environment: authEnvironment,
            initialState: initialAuthState)

        let credentialStoreMachine = StateMachine(
            resolver: credentialStoreResolver,
            environment: credentialEnvironment)

        let plugin = AWSCognitoAuthPlugin()

        plugin.configure(
            authConfiguration: authConfiguration,
            authEnvironment: authEnvironment,
            authStateMachine: authStateMachine,
            credentialStoreStateMachine: credentialStoreMachine,
            hubEventHandler: MockAuthHubEventBehavior(),
            analyticsHandler: MockAnalyticsHandler())

        return plugin
    }

    // MARK: - Configure Helpers

    private func makeUserPool() throws -> CognitoUserPoolBehavior {
        switch authConfiguration {
        case .userPools, .userPoolsAndIdentityPools:
            return self.mockIdentityProvider
        default:
            fatalError()
        }
    }

    private func makeIdentityClient() throws -> CognitoIdentityBehavior {
        switch authConfiguration {
        case .identityPools, .userPoolsAndIdentityPools:
            return mockIdentity
        default:
            fatalError()
        }
    }

    private func makeHostedUISession() -> HostedUISessionBehavior {
        return MockHostedUISession(result: .success([
            .init(name: "state", value: "mockState"),
            .init(name: "code", value: "mockProof")
        ]))
    }

    private func makeURLSession() -> URLSession {
        return URLSession.shared
    }

    private func makeRandomString() -> RandomStringBehavior {
        return MockRandomStringGenerator(mockString: "mockState", mockUUID: "mockUUID")
    }

    private func makeCognitoASF() -> AdvancedSecurityBehavior {
        MockASF()
    }

    private func makeUserPoolAnalytics() -> UserPoolAnalyticsBehavior {
        MockAnalyticsHandler()
    }

    private func makeCredentialStore() -> AmplifyAuthCredentialStoreBehavior {
        MockAmplifyStore()
    }

    private func makeLegacyKeychainStore(service: String) -> KeychainStoreBehavior {
        MockKeychainStoreBehavior(data: "mockedData")
    }

    private func makeCredentialStoreClient() -> CredentialStoreStateBehavior {
        MockCredentialStoreOperationClient()
    }


    private func makeAuthEnvironment(authConfiguration: AuthConfiguration) -> AuthEnvironment {

        let log = Amplify.Logging.logger(forCategory: "awsCognitoAuthPluginTest")

        switch authConfiguration {
        case .userPools(let userPoolConfigurationData):
            let authenticationEnvironment = authenticationEnvironment(
                userPoolConfigData: userPoolConfigurationData)

            return AuthEnvironment(
                configuration: authConfiguration,
                userPoolConfigData: userPoolConfigurationData,
                identityPoolConfigData: nil,
                authenticationEnvironment: authenticationEnvironment,
                authorizationEnvironment: nil,
                credentialsClient: makeCredentialStoreClient(),
                logger: log)

        case .identityPools(let identityPoolConfigurationData):
            let authorizationEnvironment = authorizationEnvironment(
                identityPoolConfigData: identityPoolConfigurationData)
            return AuthEnvironment(
                configuration: authConfiguration,
                userPoolConfigData: nil,
                identityPoolConfigData: identityPoolConfigurationData,
                authenticationEnvironment: nil,
                authorizationEnvironment: authorizationEnvironment,
                credentialsClient: makeCredentialStoreClient(),
                logger: log)

        case .userPoolsAndIdentityPools(let userPoolConfigurationData,
                                        let identityPoolConfigurationData):
            let authenticationEnvironment = authenticationEnvironment(
                userPoolConfigData: userPoolConfigurationData)
            let authorizationEnvironment = authorizationEnvironment(
                identityPoolConfigData: identityPoolConfigurationData)
            return AuthEnvironment(
                configuration: authConfiguration,
                userPoolConfigData: userPoolConfigurationData,
                identityPoolConfigData: identityPoolConfigurationData,
                authenticationEnvironment: authenticationEnvironment,
                authorizationEnvironment: authorizationEnvironment,
                credentialsClient: makeCredentialStoreClient(),
                logger: log)
        }
    }

    private func authenticationEnvironment(userPoolConfigData: UserPoolConfigurationData) -> AuthenticationEnvironment {

        let srpAuthEnvironment = BasicSRPAuthEnvironment(userPoolConfiguration: userPoolConfigData,
                                                         cognitoUserPoolFactory: makeUserPool)
        let srpSignInEnvironment = BasicSRPSignInEnvironment(srpAuthEnvironment: srpAuthEnvironment)
        let userPoolEnvironment = BasicUserPoolEnvironment(
            userPoolConfiguration: userPoolConfigData,
            cognitoUserPoolFactory: makeUserPool,
            cognitoUserPoolASFFactory: makeCognitoASF,
            cognitoUserPoolAnalyticsHandlerFactory: makeUserPoolAnalytics)
        let hostedUIEnvironment = hostedUIEnvironment(userPoolConfigData)
        return BasicAuthenticationEnvironment(srpSignInEnvironment: srpSignInEnvironment,
                                              userPoolEnvironment: userPoolEnvironment,
                                              hostedUIEnvironment: hostedUIEnvironment)
    }

    private func hostedUIEnvironment(_ configuration: UserPoolConfigurationData) -> HostedUIEnvironment? {
        guard let hostedUIConfig = configuration.hostedUIConfig else {
            return nil
        }
        return BasicHostedUIEnvironment(configuration: hostedUIConfig,
                                        hostedUISessionFactory: makeHostedUISession,
                                        urlSessionFactory: makeURLSession,
                                        randomStringFactory: makeRandomString)
    }

    private func authorizationEnvironment(
        identityPoolConfigData: IdentityPoolConfigurationData) -> BasicAuthorizationEnvironment {
            BasicAuthorizationEnvironment(identityPoolConfiguration: identityPoolConfigData,
                                          cognitoIdentityFactory: makeIdentityClient)
        }

    private func credentialStoreEnvironment(authConfiguration: AuthConfiguration) -> CredentialEnvironment {
        let log = Amplify.Logging.logger(forCategory: "awsCognitoAuthPluginTest")
        return CredentialEnvironment(
            authConfiguration: authConfiguration,
            credentialStoreEnvironment: BasicCredentialStoreEnvironment(
                amplifyCredentialStoreFactory: makeCredentialStore,
                legacyKeychainStoreFactory: makeLegacyKeychainStore(service:)
            ),
            logger: log
        )
    }

}
