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

struct FeatureSpecification: Codable {

    var description: String
    var preConditions: Preconditions
    var api: API
    var validations: [JSONValue]

    init(fileName: String,
         fileExtension: String = "",
         subdirectory: String) {
        let bundle = Bundle.authCognitoTestBundle()
        let url = bundle.url(
            forResource: fileName,
            withExtension: fileExtension,
            subdirectory: subdirectory)!
        let fileData: Data = try! Data(contentsOf: url)
        self = try! JSONDecoder().decode(
            FeatureSpecification.self, from: fileData)
    }
}

struct Preconditions: Codable {

    enum CodingKeys: String, CodingKey {
        case amplifyConfigurationPath = "amplify-configuration"
        case initialAuthStatePath = "state"
        case mockedResponses
    }

    var amplifyConfiguration: AmplifyConfiguration
    var initialAuthState: AuthState
    var mockedResponses: [JSONValue]

    init(amplifyConfiguration: AmplifyConfiguration,
         initialAuthState: AuthState,
         expectedResponses: [JSONValue]) {
        self.initialAuthState = initialAuthState
        self.amplifyConfiguration = amplifyConfiguration
        self.mockedResponses = expectedResponses
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let amplifyConfigurationFile = try values.decode(String.self, forKey: .amplifyConfigurationPath)
        let initialAuthStateFile = try values.decode(String.self, forKey: .initialAuthStatePath)

        self.amplifyConfiguration = AmplifyConfiguration(
            fileName: amplifyConfigurationFile)
        self.initialAuthState = AuthState.initialize(
            fileName: initialAuthStateFile)
        self.mockedResponses = try  values.decode([JSONValue].self, forKey: .mockedResponses)
    }

    public func encode(to encoder: Encoder) throws {
        fatalError("Encoding not supported")
    }

}

struct API: Codable {
    enum CodingKeys: String, CodingKey {
        case name
        case params
        case options
    }

    let name: APIName
    let params: JSONValue
    let options: JSONValue

    enum APIName: String, Codable {
        case resetPassword
        case forgotPassword
        case signUp
        case signIn
        case deleteUser
        case confirmSignIn

        
        case getId
        case getCredentialsForIdentity
        case confirmDevice
        case initiateAuth
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        name = try values.decode(APIName.self, forKey: .name)
        params = try values.decode(JSONValue.self, forKey: .params)
        options = try values.decode(JSONValue.self, forKey: .options)
    }

    public func encode(to encoder: Encoder) throws {
        fatalError("Encoding not supported")
    }
}
