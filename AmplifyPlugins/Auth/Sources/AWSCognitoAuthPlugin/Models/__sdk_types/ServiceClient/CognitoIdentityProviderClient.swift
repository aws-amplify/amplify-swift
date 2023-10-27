//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/26/23.
//

import Foundation
import AWSPluginsCore
import Amplify

public struct CognitoIdentityProviderClientConfiguration {
    let region: String
    let endpointResolver: EndpointResolver?
    let encoder: JSONEncoder
    let decoder: JSONDecoder
}

public class CognitoIdentityProviderClient {
    let configuration: CognitoIdentityProviderClientConfiguration

    init(configuration: CognitoIdentityProviderClientConfiguration) {
        self.configuration = configuration
    }
}

extension CognitoIdentityProviderClient: DefaultLogger {
    public static let log: Logger = Amplify.Logging.logger(
        forCategory: CategoryType.auth.displayName,
        forNamespace: "CognitoIdentityProviderClient"
    )

    public var log: Logger {
        Self.log
    }
}


extension CognitoIdentityProviderClient: CognitoUserPoolBehavior {
    /// Throws InitiateAuthOutputError
    func initiateAuth(input: InitiateAuthInput) async throws -> InitiateAuthOutputResponse  {
        log.debug("\(#function) entry point")
        log.debug("\(#function) with input: \(input)")

        return try await request(
            action: .initiateAuth(region: configuration.region),
            input: input
        )
    }

    /// Throws RespondToAuthChallengeOutputError
    func respondToAuthChallenge(
        input: RespondToAuthChallengeInput
    ) async throws -> RespondToAuthChallengeOutputResponse {
        log.debug("\(#function) entry point")
        log.debug("\(#function) with input: \(input)")

        return try await request(
            action: .respondToAuthChallenge(region: configuration.region),
            input: input
        )
    }

    /// Throws SignUpOutputError
    func signUp(input: SignUpInput) async throws -> SignUpOutputResponse {
        log.debug("\(#function) entry point")
        log.debug("\(#function) with input: \(input)")

        return try await request(
            action: .signUp(region: configuration.region),
            input: input
        )
    }

    /// Throws ConfirmSignUpOutputError
    func confirmSignUp(input: ConfirmSignUpInput) async throws -> ConfirmSignUpOutputResponse {
        log.debug("\(#function) entry point")
        log.debug("\(#function) with input: \(input)")

        return try await request(
            action: .confirmSignUp(region: configuration.region),
            input: input
        )
    }

    /// Throws GlobalSignOutOutputError
    func globalSignOut(input: GlobalSignOutInput) async throws -> GlobalSignOutOutputResponse {
        log.debug("\(#function) entry point")
        log.debug("\(#function) with input: \(input)")

        return try await request(
            action: .globalSignOut(region: configuration.region),
            input: input
        )
    }

    /// Throws RevokeTokenOutputError
    func revokeToken(input: RevokeTokenInput) async throws -> RevokeTokenOutputResponse {
        log.debug("\(#function) entry point")
        log.debug("\(#function) with input: \(input)")

        return try await request(
            action: .revokeToken(region: configuration.region),
            input: input
        )
    }

    // MARK: - User Attribute API's

    /// Throws GetUserAttributeVerificationCodeOutputError
    func getUserAttributeVerificationCode(input: GetUserAttributeVerificationCodeInput) async throws -> GetUserAttributeVerificationCodeOutputResponse {
        log.debug("\(#function) entry point")
        log.debug("\(#function) with input: \(input)")

        return try await request(
            action: .getUserAttributeVerificationCode(region: configuration.region),
            input: input
        )
    }

    /// Throws GetUserOutputError
    func getUser(input: GetUserInput) async throws -> GetUserOutputResponse {
        log.debug("\(#function) entry point")
        log.debug("\(#function) with input: \(input)")

        return try await request(
            action: .getUser(region: configuration.region),
            input: input
        )
    }

    /// Throws UpdateUserAttributesOutputError
    func updateUserAttributes(input: UpdateUserAttributesInput) async throws -> UpdateUserAttributesOutputResponse {
        log.debug("\(#function) entry point")
        log.debug("\(#function) with input: \(input)")

        return try await request(
            action: .updateUserAttributes(region: configuration.region),
            input: input
        )
    }

    /// Verifies the specified user attributes in the user pool.
    /// Throws VerifyUserAttributeOutputError
    func verifyUserAttribute(input: VerifyUserAttributeInput) async throws -> VerifyUserAttributeOutputResponse {
        log.debug("\(#function) entry point")
        log.debug("\(#function) with input: \(input)")

        return try await request(
            action: .verifyUserAttribute(region: configuration.region),
            input: input
        )
    }

    /// Changes the password for a specified user in a user pool.
    /// Throws ChangePasswordOutputError
    func changePassword(input: ChangePasswordInput) async throws -> ChangePasswordOutputResponse {
        log.debug("\(#function) entry point")
        log.debug("\(#function) with input: \(input)")

        return try await request(
            action: .changePassword(region: configuration.region),
            input: input
        )
    }

    /// Delete the signed in user from the user pool.
    /// Throws DeleteUserOutputError
    func deleteUser(input: DeleteUserInput) async throws -> DeleteUserOutputResponse {
        log.debug("\(#function) entry point")
        log.debug("\(#function) with input: \(input)")

        return try await request(
            action: .deleteUser(region: configuration.region),
            input: input
        )
    }

    /// Resends sign up code
    /// Throws ResendConfirmationCodeOutputError
    func resendConfirmationCode(input: ResendConfirmationCodeInput) async throws -> ResendConfirmationCodeOutputResponse {
        log.debug("\(#function) entry point")
        log.debug("\(#function) with input: \(input)")

        return try await request(
            action: .resendConfirmationCode(region: configuration.region),
            input: input
        )
    }

    /// Resets password
    /// Throws ForgotPasswordOutputError
    func forgotPassword(input: ForgotPasswordInput) async throws -> ForgotPasswordOutputResponse {
        log.debug("\(#function) entry point")
        log.debug("\(#function) with input: \(input)")

        return try await request(
            action: .forgotPassword(region: configuration.region),
            input: input
        )
    }

    /// Confirm Reset password
    /// Throws ConfirmForgotPasswordOutputError
    func confirmForgotPassword(input: ConfirmForgotPasswordInput) async throws -> ConfirmForgotPasswordOutputResponse {
        log.debug("\(#function) entry point")
        log.debug("\(#function) with input: \(input)")

        return try await request(
            action: .confirmForgotPassword(region: configuration.region),
            input: input
        )
    }

    /// Lists the devices
    func listDevices(input: ListDevicesInput) async throws -> ListDevicesOutputResponse {
        log.debug("\(#function) entry point")
        log.debug("\(#function) with input: \(input)")

        return try await request(
            action: .listDevices(region: configuration.region),
            input: input
        )
    }

    /// Updates the device status
    func updateDeviceStatus(input: UpdateDeviceStatusInput) async throws -> UpdateDeviceStatusOutputResponse {
        log.debug("\(#function) entry point")
        log.debug("\(#function) with input: \(input)")

        return try await request(
            action: .updateDeviceStatus(region: configuration.region),
            input: input
        )
    }

    /// Forgets the specified device.
    func forgetDevice(input: ForgetDeviceInput) async throws -> ForgetDeviceOutputResponse {
        log.debug("\(#function) entry point")
        log.debug("\(#function) with input: \(input)")

        return try await request(
            action: .forgetDevice(region: configuration.region),
            input: input
        )
    }

    /// Confirms tracking of the device. This API call is the call that begins device tracking.
    /// Throws ConfirmDeviceOutputError
    func confirmDevice(input: ConfirmDeviceInput) async throws -> ConfirmDeviceOutputResponse {
        log.debug("\(#function) entry point")
        log.debug("\(#function) with input: \(input)")

        return try await request(
            action: .confirmDevice(region: configuration.region),
            input: input
        )
    }

    /// Creates a new request to associate a new software token for the user
    /// Throws AssociateSoftwareTokenOutputError
    func associateSoftwareToken(input: AssociateSoftwareTokenInput) async throws -> AssociateSoftwareTokenOutputResponse {
        log.debug("\(#function) entry point")
        log.debug("\(#function) with input: \(input)")

        return try await request(
            action: .associateSoftwareToken(region: configuration.region),
            input: input
        )
    }

    /// Register a user's entered time-based one-time password (TOTP) code and mark the user's software token MFA status as "verified" if successful.
    /// Throws VerifySoftwareTokenOutputError
    func verifySoftwareToken(input: VerifySoftwareTokenInput) async throws -> VerifySoftwareTokenOutputResponse {
        log.debug("\(#function) entry point")
        log.debug("\(#function) with input: \(input)")

        return try await request(
            action: .verifySoftwareToken(region: configuration.region),
            input: input
        )
    }

    /// Set the user's multi-factor authentication (MFA) method preference, including which MFA factors are activated and if any are preferred.
    /// Throws SetUserMFAPreferenceOutputError
    func setUserMFAPreference(input: SetUserMFAPreferenceInput) async throws -> SetUserMFAPreferenceOutputResponse {
        log.debug("\(#function) entry point")
        log.debug("\(#function) with input: \(input)")

        return try await request(
            action: .setUserMFAPreference(region: configuration.region),
            input: input
        )
    }

    private func request<Input, Output>(
        action: CognitoIdentityProviderAction<Input, Output>,
        input: Input,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) async throws -> Output {
        log.debug("[\(file)] [\(function)] [\(line)] request entry point")
        log.debug("[\(file)] [\(function)] [\(line)] input: \(input)")

        let requestData = try action.encode(input, configuration.encoder)
        log.debug("[\(file)] [\(function)] [\(line)] requestData size size: \(requestData.count)")

        let url = try action.url(region: configuration.region)

        // TODO: generate user-agent
        let userAgent = "amplify-swift/2.x ua/2.0 api/cognito-identity#1.0 os/ios#17.0.1 lang/swift#5.8 cfg/retry-mode#legacy"
        log.debug("[\(file)] [\(function)] [\(line)] userAgent: \(userAgent)")

        var request = URLRequest(url: url)
        request.setValue(action.xAmzTarget, forHTTPHeaderField: "X-Amz-Target")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/x-amz-json-1.1", forHTTPHeaderField: "Content-Type")
        request.setValue(String(requestData.count), forHTTPHeaderField: "Content-Length")
        request.httpMethod = action.method.verb
        request.httpBody = requestData

//        log.debug("[\(file)] [\(function)] [\(line)] unsigned request url: \(url)")
//        let credentials = try await configuration.credentialsProvider.fetchCredentials()
//        let signer = SigV4Signer(
//            credentials: credentials,
//            serviceName: configuration.signingName,
//            region: configuration.region
//        )
//
//        let signedRequest = signer.sign(
//            url: url,
//            method: .post,
//            body: .data(requestData),
//            headers: [
//                "X-Amz-Target": "",
//                "Content-Type": "application/x-amz-json-1.1",
//                "User-Agent": userAgent,
//                "Content-Length": String(requestData.count)
//            ]
//        )

        log.debug("[\(file)] [\(function)] [\(line)] Request URL: \(request.url as Any)")
        log.debug("[\(file)] [\(function)] [\(line)] Request Headers: \(request.allHTTPHeaderFields as Any)")
        log.debug("[\(file)] [\(function)] [\(line)] Starting network request")

        let (responseData, urlResponse) = try await URLSession.shared.upload(
            for: request,
            from: requestData
        )
        log.debug("Completed network request in \(#function) with URLResponse: \(urlResponse)")

        guard let httpURLResponse = urlResponse as? HTTPURLResponse else {
            log.error("""
            Couldn't case from `URLResponse` to `HTTPURLResponse`
            This shouldn't happen. Received URLResponse: \(urlResponse)
            """)
            throw PlaceholderError() // this shouldn't happen
        }

        log.debug("[\(file)] [\(function)] [\(line)] HTTPURLResponse in \(#function): \(httpURLResponse)")
        guard (200..<300).contains(httpURLResponse.statusCode) else {
            log.error("Expected a 2xx status code, received: \(httpURLResponse.statusCode)")
            throw try action.mapError(responseData, httpURLResponse)
        }

        log.debug("[\(file)] [\(function)] [\(line)] Attempting to decode response object in \(#function)")
        let response = try action.decode(responseData, configuration.decoder)
        log.debug("[\(file)] [\(function)] [\(line)] Decoded response in `\(Output.self)`: \(response)")

        return response
    }

}
