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

public class AWSAuthForgetDeviceOperation: AmplifyOperation<AuthForgetDeviceRequest, Void, AuthError>, AuthForgetDeviceOperation {
    
    typealias CognitoUserPoolFactory = () throws -> CognitoUserPoolBehavior
    
    private let authStateMachine: AuthStateMachine
    private let userPoolFactory: CognitoUserPoolFactory
    private let fetchAuthSessionHelper: FetchAuthSessionOperationHelper
    
    init(_ request: AuthForgetDeviceRequest,
         authStateMachine: AuthStateMachine,
         userPoolFactory: @escaping CognitoUserPoolFactory,
         resultListener: ResultListener?) {
        self.authStateMachine = authStateMachine
        self.userPoolFactory = userPoolFactory
        self.fetchAuthSessionHelper = FetchAuthSessionOperationHelper()
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.forgetDeviceAPI,
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
                        await self?.forgetDevice(with: tokens.accessToken)
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
    
    func forgetDevice(with accessToken: String) async {
        do {
            let userPoolService = try userPoolFactory()
            let input : ForgetDeviceInput
            if let device = request.device {
                input = ForgetDeviceInput(accessToken: accessToken, deviceKey: device.id)
            } else {
                // TODO: pass in current device ID
                input = ForgetDeviceInput(accessToken: accessToken, deviceKey: nil)
            }
            
            _ = try await userPoolService.forgetDevice(input: input)
            
            if self.isCancelled {
                finish()
                return
            }
            
            self.dispatch()
        } catch let error as ForgetDeviceOutputError {
            self.dispatch(error.authError)
        } catch let error as SdkError<ForgetDeviceOutputError> {
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
