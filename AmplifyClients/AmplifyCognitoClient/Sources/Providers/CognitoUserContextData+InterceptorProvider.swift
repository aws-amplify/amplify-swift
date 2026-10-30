//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// Re-exported with its SPI, so `@_spi(AmplifyExperimental) import AmplifyCognitoClient` also names `CognitoUserContextData`.
@_spi(AmplifyExperimental) @_exported import AmplifyCognitoASF
import AWSCognitoIdentityProvider
import ClientRuntime
import class SmithyHTTPAPI.HTTPRequest
import class SmithyHTTPAPI.HTTPResponse

@_spi(AmplifyExperimental)
public extension CognitoUserContextData {

    /// Returns an interceptor provider that adds user context data to the requests a `CognitoIdentityProviderClient`
    /// sends. Add it once, when you make the client:
    ///
    /// ```swift
    /// let contextData = CognitoUserContextData(userPoolId: userPoolId, userPoolClientId: clientId)
    ///
    /// var config = try await CognitoIdentityProviderClient.CognitoIdentityProviderClientConfig(region: region)
    /// config.addInterceptorProvider(contextData.interceptorProvider())
    /// let cognito = CognitoIdentityProviderClient(config: config)
    /// ```
    ///
    /// It sets `userContextData` on the seven requests that have it (`InitiateAuth`, `RespondToAuthChallenge`,
    /// `SignUp`, `ConfirmSignUp`, `ForgotPassword`, `ConfirmForgotPassword` and `ResendConfirmationCode`) when their
    /// `clientId` is this app client's, and leaves every other request alone. Each call gets data made for it by
    /// `encodedData(username:deviceId:)`, for the user the request names: `USERNAME` in `authParameters` or
    /// `challengeResponses`, else `username`. A refresh-token sign-in names none, so its data names `"unknown"`, where
    /// the AWS SDK for iOS named the signed-in user.
    ///
    /// A request whose `userContextData` already has a non-empty `encodedData` is sent as it is; otherwise an
    /// `ipAddress` it carries is kept. A retried call resends the same data. The device is read on the main actor. The
    /// data carries the username and device identifiers, so don't log request bodies (`clientLogMode`).
    ///
    /// A hosted UI sign-in URL your app builds itself and your backend's `Admin*` requests still need
    /// `encodedData(username:deviceId:)`.
    ///
    /// - Parameter deviceId: Returns an ID that stays the same for this device, such as a UUID your app keeps in the
    ///   keychain for the user pool, given the username the request names (`nil` if it names none). Without it, or
    ///   when it returns `nil`, the identifier for vendor is sent, or no device ID where there is none, as on macOS.
    func interceptorProvider(
        deviceId: (@Sendable (_ username: String?) async -> String?)? = nil
    ) -> some HttpInterceptorProvider & Sendable {
        UserContextDataInterceptorProvider(contextData: self, deviceId: deviceId)
    }
}

/// The provider `CognitoUserContextData.interceptorProvider(deviceId:)` returns.
struct UserContextDataInterceptorProvider: HttpInterceptorProvider, Sendable {

    typealias DeviceIdProvider = @Sendable (_ username: String?) async -> String?

    let contextData: CognitoUserContextData
    let deviceId: DeviceIdProvider?
    let device: @Sendable (_ deviceId: String?) -> any ASFDeviceBehavior
    let appInfo: @Sendable () -> any ASFAppInfoBehavior

    /// `device` and `appInfo` are the system's unless a test fixes them.
    init(
        contextData: CognitoUserContextData,
        deviceId: DeviceIdProvider? = nil,
        device: @escaping @Sendable (_ deviceId: String?) -> any ASFDeviceBehavior = { ASFDeviceInfo(id: $0 ?? "") },
        appInfo: @escaping @Sendable () -> any ASFAppInfoBehavior = { ASFAppInfo() }
    ) {
        self.contextData = contextData
        self.deviceId = deviceId
        self.device = device
        self.appInfo = appInfo
    }

    func create<InputType, OutputType>() -> any Interceptor<InputType, OutputType, HTTPRequest, HTTPResponse> {
        UserContextDataInterceptor<InputType, OutputType>(provider: self)
    }
}

struct UserContextDataInterceptor<InputType, OutputType>: Interceptor {
    typealias RequestType = HTTPRequest
    typealias ResponseType = HTTPResponse

    let provider: UserContextDataInterceptorProvider

    func modifyBeforeSerialization(context: some MutableInput<InputType>) async throws {
        let contextData = provider.contextData
        guard var input = context.getInput() as? any UserContextDataInput,
              input.userContextData?.encodedData?.isEmpty ?? true,
              !contextData.userPoolId.isEmpty,
              !contextData.userPoolClientId.isEmpty,
              input.clientId == contextData.userPoolClientId else {
            return
        }
        let username = input.userContextDataUsername
        let deviceId = await provider.deviceId?(username)
        guard let encodedData = await contextData.encodedData(
            username: username,
            deviceId: deviceId,
            device: provider.device(deviceId),
            appInfo: provider.appInfo()
        ) else {
            return
        }
        var userContextData = input.userContextData ?? .init()
        userContextData.encodedData = encodedData
        input.userContextData = userContextData
        guard let updated = input as? InputType else {
            return
        }
        context.updateInput(updated: updated)
    }
}

/// The seven inputs that carry `UserContextDataType`.
protocol UserContextDataInput {
    var clientId: String? { get }
    var userContextData: CognitoIdentityProviderClientTypes.UserContextDataType? { get set }
    /// The username the request names, if it names one.
    var userContextDataUsername: String? { get }
}

extension InitiateAuthInput: UserContextDataInput {
    var userContextDataUsername: String? { authParameters?["USERNAME"] }
}

extension RespondToAuthChallengeInput: UserContextDataInput {
    var userContextDataUsername: String? { challengeResponses?["USERNAME"] }
}

extension SignUpInput: UserContextDataInput {
    var userContextDataUsername: String? { username }
}

extension ConfirmSignUpInput: UserContextDataInput {
    var userContextDataUsername: String? { username }
}

extension ForgotPasswordInput: UserContextDataInput {
    var userContextDataUsername: String? { username }
}

extension ConfirmForgotPasswordInput: UserContextDataInput {
    var userContextDataUsername: String? { username }
}

extension ResendConfirmationCodeInput: UserContextDataInput {
    var userContextDataUsername: String? { username }
}
