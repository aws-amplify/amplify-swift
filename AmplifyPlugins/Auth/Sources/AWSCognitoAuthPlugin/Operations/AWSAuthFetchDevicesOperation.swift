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

public class AWSAuthFetchDevicesOperation: AmplifyOperation<AuthFetchDevicesRequest, [AuthDevice], AuthError>, AuthFetchDevicesOperation {
    
    typealias CognitoUserPoolFactory = () throws -> CognitoUserPoolBehavior
    
    private let authStateMachine: AuthStateMachine
    private let userPoolFactory: CognitoUserPoolFactory
    private let fetchAuthSessionHelper: FetchAuthSessionOperationHelper
    
    init(_ request: AuthFetchDevicesRequest,
         authStateMachine: AuthStateMachine,
         userPoolFactory: @escaping CognitoUserPoolFactory,
         resultListener: ResultListener?) {
        self.authStateMachine = authStateMachine
        self.userPoolFactory = userPoolFactory
        self.fetchAuthSessionHelper = FetchAuthSessionOperationHelper()
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.fetchDevicesAPI,
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
                guard let cognitoTokenProvider = session as? AuthCognitoTokensProvider,
                      let tokens = try? cognitoTokenProvider.getCognitoTokens().get() else {
                          self?.dispatch(AuthError.unknown("Unable to fetch auth session", nil))
                          return
                      }
                Task.init { [weak self] in
                    await self?.fetchDevices(with: tokens.accessToken)
                }
            case .failure(let error):
                self?.dispatch(error)
            }
        }
    }
    
    func fetchDevices(with accessToken: String) async {
        do {
            let userPoolService = try userPoolFactory()
            let input = ListDevicesInput(accessToken: accessToken)
            let result = try await userPoolService.listDevices(input: input)
            
            if self.isCancelled {
                finish()
                return
            }
            
            guard let devices = result.devices else {
                let authError = AuthError.unknown("Unable to get devices list from response",
                                                  nil)
                self.dispatch(authError)
                return
            }
            
            let deviceList = devices.reduce(into: [AuthDevice]()) {
                $0.append($1.toAWSAuthDevice())
            }
            self.dispatch(deviceList)
        } catch let error as ListDevicesOutputError {
            self.dispatch(error.authError)
        } catch let error as SdkError<ListDevicesOutputError> {
            self.dispatch(error.authError)
        } catch let error as AuthError {
            self.dispatch(error)
        } catch let error {
            let error = AuthError.unknown("Unable to create a Swift SDK user pool service", error)
            self.dispatch(error)
        }
    }
    
    
    private func dispatch(_ result: [AuthDevice]) {
        let result = OperationResult.success(result)
        dispatch(result: result)
    }
    
    private func dispatch(_ error: AuthError) {
        let result = OperationResult.failure(error)
        dispatch(result: result)
    }
    
}
