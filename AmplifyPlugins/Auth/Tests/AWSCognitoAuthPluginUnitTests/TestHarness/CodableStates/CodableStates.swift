//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSCognitoAuthPlugin
import AWSCognitoIdentityProvider
import Foundation
import AWSPluginsCore
import Amplify

extension AuthState: Codable {

    enum CodingKeys: String, CodingKey {
        case type
        case authenticationState = "AuthenticationState"
        case authorizationState = "AuthorizationState"
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        let type = try values.decode(String.self, forKey: .type)

        if type == "AuthState.Configured" {
            let authenticationState = try values.decode(AuthenticationState.self, forKey: .authenticationState)
            let authorizationState = try values.decode(AuthorizationState.self, forKey: .authorizationState)
            self = .configured(
                authenticationState,
                authorizationState)
        } else {
            fatalError("Decoding not supported")
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .configured(let authenticationState, let authorizationState):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(authenticationState, forKey: .authenticationState)
            try container.encode(authorizationState, forKey: .authorizationState)
        default:
            fatalError("not implemented")
        }

    }

    static func initialize(
        fileName: String,
        with fileExtension: String = "") -> AuthState {
        let bundle = Bundle.authCognitoTestBundle()
        let url = bundle.url(
            forResource: fileName,
            withExtension: fileExtension,
            subdirectory: AuthTestHarnessConstants.authStatesResourcePath)!
        let fileData: Data = try! Data(contentsOf: url)
        return try! JSONDecoder().decode(
            AuthState.self, from: fileData)
    }
}

extension AuthenticationState: Codable {

    enum CodingKeys: String, CodingKey {
        case type
        case signedInData
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        let type = try values.decode(String.self, forKey: .type)
        if type == "AuthenticationState.SignedIn" {
            // TODO: Discuss with android team
            // let signedInData = try values.decode(SignedInData.self, forKey: .signedInData)
            self = .signedIn(.testData)
        } else {
            fatalError("Decoding not supported")
        }
    }

    public func encode(to encoder: Encoder) throws {

        switch self {
        default:
            fatalError("encoding not supported")
        }

    }
}

extension AuthorizationState: Codable {

    enum CodingKeys: String, CodingKey {
        case type
        case amplifyCredential
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        let type = try values.decode(String.self, forKey: .type)
        if type == "AuthorizationState.SessionEstablished" {
            // TODO: Discuss with android team
            // let amplifyCredential = try values.decode(AmplifyCredentials.self, forKey: .amplifyCredential)
            self = .sessionEstablished(.testData)
        } else {
            fatalError("Decoding not supported")
        }

    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        default:
            fatalError()
        }
    }
}

extension DeviceMetadata {

    public init(from decoder: Decoder) throws {
        self = .noData
    }

    public func encode(to encoder: Encoder) throws {
        fatalError()
    }
}

extension SRPSignInState: Codable {

    public init(from decoder: Decoder) throws {
        self = .notStarted
    }

    public func encode(to encoder: Encoder) throws {

    }
}

extension SignOutState: Codable {
    public init(from decoder: Decoder) throws {
        self = .notStarted
    }

    public func encode(to encoder: Encoder) throws {

    }
}

extension SignInState: Codable {
    public init(from decoder: Decoder) throws {
        self = .notStarted
    }

    public func encode(to encoder: Encoder) throws {

    }
}

extension SignInChallengeState: Codable {
    public init(from decoder: Decoder) throws {
        self = .notStarted
    }

    public func encode(to encoder: Encoder) throws {

    }
}

extension RefreshSessionState: Codable {
    public init(from decoder: Decoder) throws {
        self = .notStarted
    }

    public func encode(to encoder: Encoder) throws {

    }
}

extension DeleteUserState: Codable {
    public init(from decoder: Decoder) throws {
        self = .notStarted
    }

    public func encode(to encoder: Encoder) throws {

    }
}

extension CustomSignInState: Codable {
    public init(from decoder: Decoder) throws {
        self = .notStarted
    }

    public func encode(to encoder: Encoder) throws {

    }
}

extension CredentialStoreState: Codable {
    public init(from decoder: Decoder) throws {
        self = .notConfigured
    }

    public func encode(to encoder: Encoder) throws {

    }
}

extension FetchAuthSessionState: Codable {

    enum CodingKeys: CodingKey {
        case notStarted
        case fetchingIdentityID
        case fetchingAWSCredentials
        case fetched
    }

    public init(from decoder: Decoder) throws {
        fatalError()
    }

    public func encode(to encoder: Encoder) throws {

    }
}

extension SignUpOutputResponse: Codable {
    enum CodingKeys: CodingKey {
        case codeDeliveryDetails
        case userConfirmed
        case userSub
    }

    public init(from decoder: Decoder) throws {
        self.init()
        let containerValues = try decoder.container(keyedBy: CodingKeys.self)
        self.userConfirmed = try containerValues.decode(Swift.Bool.self, forKey: .userConfirmed)
        self.codeDeliveryDetails = try containerValues.decodeIfPresent(CognitoIdentityProviderClientTypes.CodeDeliveryDetailsType.self, forKey: .codeDeliveryDetails)
        self.userSub = try containerValues.decodeIfPresent(String.self, forKey: .userSub)
    }

    public func encode(to encoder: Encoder) throws {
        fatalError("This implementation is not needed")
    }
}

extension AuthorizationError: Codable {
    public init(from decoder: Decoder) throws {
        self = .sessionExpired
    }

    public func encode(to encoder: Encoder) throws {

    }
}

extension SignInError: Codable {

    enum CodingKeys: CodingKey {
        case configuration
        case inputValidation
        case invalidServiceResponse
        case calculation
        case hostedUI
        case service
        case unknown
    }

    public init(from decoder: Decoder) throws {

        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let configuration = try values.decodeIfPresent(String.self, forKey: .configuration) {
            self = .configuration(message: configuration)
        } else if let inputValidation = try values.decodeIfPresent(String.self, forKey: .inputValidation) {
            self = .inputValidation(field: inputValidation)
        } else if let invalidServiceResponse = try values.decodeIfPresent(String.self, forKey: .invalidServiceResponse) {
            self = .invalidServiceResponse(message: invalidServiceResponse)
        } else if let unknown = try values.decodeIfPresent(String.self, forKey: .unknown) {
            self = .unknown(message: unknown)
        } else if let calculation = try values.decodeIfPresent(SRPError.self, forKey: .calculation) {
            self = .calculation(calculation)
        } else {
            fatalError("Decoding the key not supported")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {

        case .configuration(message: let message):
            try container.encode(message, forKey: .configuration)
        case .inputValidation(field: let message):
            try container.encode(message, forKey: .inputValidation)
        case .invalidServiceResponse(message: let message):
            try container.encode(message, forKey: .invalidServiceResponse)
        case .calculation(let error):
            try container.encode(error, forKey: .calculation)
        case .hostedUI(_):
            fatalError("service error decoding not supported")
        case .service(_):
            fatalError("service error decoding not supported")
        case .unknown(message: let message):
            try container.encode(message, forKey: .unknown)
        }
    }
}

extension SignUpError: Codable {

    enum CodingKeys: CodingKey {
        case invalidState
        case invalidUsername
        case invalidPassword
        case invalidConfirmationCode
        case service
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        if let invalidState = try values.decodeIfPresent(String.self, forKey: .invalidState) {
            self = .invalidState(message: invalidState)
        } else if let invalidUsername = try values.decodeIfPresent(String.self, forKey: .invalidUsername) {
            self = .invalidState(message: invalidUsername)
        } else if let invalidPassword = try values.decodeIfPresent(String.self, forKey: .invalidPassword) {
            self = .invalidState(message: invalidPassword)
        } else if let invalidConfirmationCode = try values.decodeIfPresent(String.self, forKey: .invalidConfirmationCode) {
            self = .invalidState(message: invalidConfirmationCode)
        } else {
            fatalError("Decoding the key not supported")
        }
        //      TODO: Check how we can decode swift error
        //        else if let invalidStateMessage = values.decodeIfPresent(String.self, forKey: .service) {
        //            self = .invalidState(message: invalidStateMessage)
        //        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {

        case .invalidState(message: let message):
            try container.encode(message, forKey: .invalidState)
        case .invalidUsername(message: let message):
            try container.encode(message, forKey: .invalidUsername)
        case .invalidPassword(message: let message):
            try container.encode(message, forKey: .invalidPassword)
        case .invalidConfirmationCode(message: let message):
            try container.encode(message, forKey: .invalidConfirmationCode)
        case .service(_):
            fatalError("service error decoding not supported")
        }
    }
}

extension FetchSessionError: Codable {
    public init(from decoder: Decoder) throws {
        self = .notAuthorized
    }

    public func encode(to encoder: Encoder) throws {

    }
}


extension KeychainStoreError: Codable {
    public init(from decoder: Decoder) throws {
        self = .unknown("", nil)
    }

    public func encode(to encoder: Encoder) throws {

    }
}



//extension SignedInData: Codable {
//
//    enum CodingKeys: String, CodingKey {
////        case userId
////        case userName = "username"
//        case signedInDate
//        case signInMethod
//        case deviceMetadata
//        case cognitoUserPoolTokens
//    }
//
//    public init(from decoder: Decoder) throws {
//        let values = try decoder.container(keyedBy: CodingKeys.self)
////        let userId = try values.decode(String.self, forKey: .userId)
////        let userName = try values.decode(String.self, forKey: .userName)
//        let signedInDate = try values.decode(Date.self, forKey: .signedInDate)
//        let cognitoUserPoolTokens = try values.decode(AWSCognitoUserPoolTokens.self, forKey: .cognitoUserPoolTokens)
//
//        //TODO: Fix decoding of the following values
//        let signInMethod = .apiBased(.userSRP)
//        let deviceMetadata = .noData
//
//        self = SignedInData(
//            signedInDate: signedInDate,
//            signInMethod: signInMethod,
//            deviceMetadata: deviceMetadata,
//            cognitoUserPoolTokens: cognitoUserPoolTokens)
//    }
//
//    public func encode(to encoder: Encoder) throws {
//
//    }
//
//}
