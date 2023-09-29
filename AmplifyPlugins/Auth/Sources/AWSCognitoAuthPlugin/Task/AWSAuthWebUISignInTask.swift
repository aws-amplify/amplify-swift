//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS)
import Foundation
import Amplify
import AWSPluginsCore

class AWSAuthWebUISignInTask: AuthWebUISignInTask, DefaultLogger {

    private let helper: HostedUISignInHelper
    private let request: AuthWebUISignInRequest
    private let authStateMachine: AuthStateMachine
    private let taskHelper: AWSAuthTaskHelper
    let eventName: HubPayloadEventName

    init(_ request: AuthWebUISignInRequest,
         authConfiguration: AuthConfiguration,
         authStateMachine: AuthStateMachine,
         eventName: String
    ) {
        self.request = request
        self.authStateMachine = authStateMachine
        self.helper = HostedUISignInHelper(request: request,
                                           authstateMachine: authStateMachine,
                                           configuration: authConfiguration)
        self.eventName = eventName
        self.taskHelper = AWSAuthTaskHelper(authStateMachine: authStateMachine)
    }

    func execute() async throws -> AuthSignInResult {
        log.verbose("Starting execution")
        do {
            await taskHelper.didStateMachineConfigured()
            let result = try await helper.initiateSignIn()
            log.verbose("Received result")
            return result
        } catch let autherror as AuthErrorConvertible {
            throw autherror.authError
        } catch {
            throw AuthError.unknown("Not able to signIn to the webUI", error)

        }
    }
    
    public static var log: Logger {
        Amplify.Logging.logger(forCategory: CategoryType.auth.displayName, forNamespace: String(describing: self))
    }
    
    public var log: Logger {
        Self.log
    }
}
#endif
