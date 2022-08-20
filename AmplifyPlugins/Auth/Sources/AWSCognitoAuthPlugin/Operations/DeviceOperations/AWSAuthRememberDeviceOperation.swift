//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import ClientRuntime
import AWSCognitoIdentityProvider

public class AWSAuthRememberDeviceOperation: AmplifyOperation<AuthRememberDeviceRequest, Void, AuthError>, AuthRememberDeviceOperation {

    typealias CognitoUserPoolFactory = () throws -> CognitoUserPoolBehavior

    private let authStateMachine: AuthStateMachine
    private let authEnvironment: AuthEnvironment
    private let fetchAuthSessionHelper: FetchAuthSessionOperationHelper

    init(_ request: AuthRememberDeviceRequest,
         authStateMachine: AuthStateMachine,
         authEnvironment: AuthEnvironment,
         resultListener: ResultListener?) {
        self.authStateMachine = authStateMachine
        self.authEnvironment = authEnvironment
        self.fetchAuthSessionHelper = FetchAuthSessionOperationHelper()
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.rememberDeviceAPI,
                   request: request,
                   resultListener: resultListener)
    }

    override public func main() {
        if isCancelled {
            finish()
            return
        }

        fetchAuthSessionHelper.fetch(authStateMachine) { [weak self] result in
            switch result {
            case .success(let session):
                guard let cognitoTokenProvider = session as? AuthCognitoTokensProvider else {
                    self?.dispatch(AuthError.unknown("Unable to fetch auth session", nil))
                    return
                }

                do {
                    let tokens = try cognitoTokenProvider.getCognitoTokens().get()
                    Task.init { [weak self] in
                        await self?.rememberDevice(with: tokens.accessToken)
                    }
                } catch let error as AuthError {
                    self?.dispatch(error)
                } catch {
                    self?.dispatch(AuthError.unknown("Unable to fetch auth session", error))
                }
            case .failure(let error):
                self?.dispatch(error)
            }
        }
    }

    func rememberDevice(with accessToken: String) async {
        do {
            let userPoolService = try authEnvironment.cognitoUserPoolFactory()
            let username = try TokenParserHelper.getAuthUser(accessToken: accessToken).username
            guard case let .metadata(deviceMetadata) = await DeviceMetadataHelper.getDeviceMetadata(
                for: authEnvironment, with: username) else {
                throw AuthError.configuration(
                    "Unable get a device key",
                    "Please validate if the plugin is setup to remember devices")
            }
            let input = UpdateDeviceStatusInput(accessToken: accessToken,
                                                deviceKey: deviceMetadata.deviceKey,
                                                deviceRememberedStatus: .remembered)
            _ = try await userPoolService.updateDeviceStatus(input: input)

            if self.isCancelled {
                finish()
                return
            }

            self.dispatch()
        } catch let error as UpdateDeviceStatusOutputError {
            self.dispatch(error.authError)
        } catch let error as SdkError<UpdateDeviceStatusOutputError> {
            self.dispatch(error.authError)
        } catch let error as AuthError {
            self.dispatch(error)
        } catch let error {
            let error = AuthError.unknown("Unable to create a Swift SDK user pool service", error)
            self.dispatch(error)
        }
    }

    private func dispatch() {
        let result = OperationResult.success(())
        dispatch(result: result)
    }

    private func dispatch(_ error: AuthError) {
        let result = OperationResult.failure(error)
        dispatch(result: result)
    }

}
