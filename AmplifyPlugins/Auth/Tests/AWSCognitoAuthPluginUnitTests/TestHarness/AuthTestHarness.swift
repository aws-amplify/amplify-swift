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


class AuthTestHarness {

    let apiTimeout = 2.0

    var authConfiguration: AuthConfiguration
    let testHarnessInput: AuthTestHarnessInput

    init(featureSpecification: FeatureSpecification) {

        let awsCognitoAuthConfig = featureSpecification.preConditions.amplifyConfiguration.auth?.plugins["awsCognitoAuthPlugin"]

        guard let jsonValueConfiguration = awsCognitoAuthConfig else {
            fatalError("Unable to get JSONValue for amplify config")
        }

        guard let authConfiguration = try? ConfigurationHelper
            .authConfiguration(jsonValueConfiguration) else {
            fatalError("Unable to create auth configuarion")
        }

        self.authConfiguration = authConfiguration
        self.testHarnessInput = AuthTestHarnessInput.createInput(
            from: featureSpecification)
    }

    func getPlugin() -> AWSCognitoAuthPlugin {

        let authResolver = AuthState.Resolver().eraseToAnyResolver()
        let authEnvironment = makeAuthEnvironment(authConfiguration: authConfiguration)

        let credentialStoreResolver = CredentialStoreState.Resolver().eraseToAnyResolver()
        let credentialEnvironment = credentialStoreEnvironment(authConfiguration: authConfiguration)

        let authStateMachine = StateMachine(
            resolver: authResolver,
            environment: authEnvironment,
            initialState: testHarnessInput.initialAuthState)

        let credentialStoreMachine = StateMachine(
            resolver: credentialStoreResolver,
            environment: credentialEnvironment)

        let plugin = AWSCognitoAuthPlugin()

        plugin.configure(
            authConfiguration: authConfiguration,
            authEnvironment: authEnvironment,
            authStateMachine: authStateMachine,
            credentialStoreStateMachine: credentialStoreMachine,
            hubEventHandler: MockAuthHubEventBehavior())

        return plugin
    }

    // MARK: - Configure Helpers

    private func makeUserPool() throws -> CognitoUserPoolBehavior {
        switch authConfiguration {
        case .userPools, .userPoolsAndIdentityPools:

            let mockUserPoolBehavior = MockIdentityProvider(
                mockChangePasswordOutputResponse: { input in
                    fatalError()
                    //                    XCTAssertEqual(input, self.featureSpecification.cognitoService.changePassword.input)
                    //                    return self.featureSpecification.cognitoService.changePassword.response
                },
                mockForgotPasswordOutputResponse: { input in
                    guard case .forgotPassword(let request, let result) = self.testHarnessInput.cognitoAPI else {
                        fatalError("Missing input")
                    }
                    if let request = request {
                        XCTAssertEqual(input.clientMetadata, request.clientMetadata)
                        XCTAssertEqual(input.clientId, request.clientId)
                        XCTAssertEqual(input.username, request.username)
                    }

                    switch result {
                    case .success(let response):
                        return response
                    case .failure(let error):
                        throw error
                    }
                }
            )
            return mockUserPoolBehavior

        default:
            fatalError()
        }
    }

    private func makeIdentityClient() throws -> CognitoIdentityBehavior {
        switch authConfiguration {
        case .identityPools, .userPoolsAndIdentityPools:

            let getId: MockIdentity.MockGetIdResponse = { _ in
                return .init(identityId: "mockIdentityId")
            }

            let getCredentials: MockIdentity.MockGetCredentialsResponse = { _ in
                let credentials = CognitoIdentityClientTypes.Credentials(
                    accessKeyId: "accessKey",
                    expiration: Date(),
                    secretKey: "secret",
                    sessionToken: "session")
                return .init(credentials: credentials, identityId: "responseIdentityID")
            }

            let mockIdentity = MockIdentity(
                mockGetIdResponse: getId,
                mockGetCredentialsResponse: getCredentials)

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

    private func makeCredentialStore() -> AmplifyAuthCredentialStoreBehavior {
        MockAmplifyStore()
    }

    private func makeLegacyKeychainStore(service: String) -> KeychainStoreBehavior {
        MockKeychainStoreBehavior(data: "mockedData")
    }

    private func makeCredentialStoreClient() -> CredentialStoreStateBehaviour {
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
                credentialStoreClientFactory: makeCredentialStoreClient,
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
                credentialStoreClientFactory: makeCredentialStoreClient,
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
                credentialStoreClientFactory: makeCredentialStoreClient,
                logger: log)
        }
    }

    private func authenticationEnvironment(userPoolConfigData: UserPoolConfigurationData) -> AuthenticationEnvironment {

        let srpAuthEnvironment = BasicSRPAuthEnvironment(userPoolConfiguration: userPoolConfigData,
                                                         cognitoUserPoolFactory: makeUserPool)
        let srpSignInEnvironment = BasicSRPSignInEnvironment(srpAuthEnvironment: srpAuthEnvironment)
        let userPoolEnvironment = BasicUserPoolEnvironment(userPoolConfiguration: userPoolConfigData,
                                                           cognitoUserPoolFactory: makeUserPool,
                                                           cognitoUserPoolASFFactory: makeCognitoASF)
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

    private func authorizationEnvironment(identityPoolConfigData: IdentityPoolConfigurationData) -> AuthorizationEnvironment {
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
