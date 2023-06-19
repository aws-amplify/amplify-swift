//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore
import ClientRuntime
import AWSCognitoIdentityProvider

protocol AuthFetchMFAPreferenceTask: AmplifyAuthTask where Request == FetchMFAPreferenceRequest,
                                                           Success == UserMFAPreference,
                                                           Failure == AuthError {}

public extension HubPayload.EventName.Auth {
    /// eventName for HubPayloads emitted by this operation
    static let fetchMFAPreferenceAPI = "Auth.fetchMFAPreferenceAPI"
}

class FetchMFAPreferenceTask: AuthFetchMFAPreferenceTask, DefaultLogger {

    typealias CognitoUserPoolFactory = () throws -> CognitoUserPoolBehavior

    private let request: FetchMFAPreferenceRequest
    private let authStateMachine: AuthStateMachine
    private let userPoolFactory: CognitoUserPoolFactory
    private let taskHelper: AWSAuthTaskHelper

    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.fetchMFAPreferenceAPI
    }

    init(_ request: FetchMFAPreferenceRequest,
         authStateMachine: AuthStateMachine,
         userPoolFactory: @escaping CognitoUserPoolFactory) {
        self.request = request
        self.authStateMachine = authStateMachine
        self.userPoolFactory = userPoolFactory
        self.taskHelper = AWSAuthTaskHelper(authStateMachine: authStateMachine)
    }

    func execute() async throws -> UserMFAPreference {
        do {
            await taskHelper.didStateMachineConfigured()
            let accessToken = try await taskHelper.getAccessToken()
            return try await fetchMFAPreference(with: accessToken)
        } catch let error as AuthErrorConvertible {
            throw error.authError
        } catch let error as AuthError {
            throw error
        } catch let error {
            throw AuthError.unknown("Unable to execute auth task", error)
        }
    }

    func fetchMFAPreference(with accessToken: String) async throws -> UserMFAPreference {
        let userPoolService = try userPoolFactory()
        let input = GetUserInput(accessToken: accessToken)
        let result = try await userPoolService.getUser(input: input)

        var enabledList: Set<MFAType>? = nil
        var preferred: MFAType? = nil

        for mfaValue in result.userMFASettingList ?? [] {

            guard let mfaType = MFAType(rawValue: mfaValue) else {
                continue
            }

            if enabledList == nil {
                enabledList = Set<MFAType>()
                enabledList?.insert(mfaType)
            } else {
                enabledList?.insert(mfaType)
            }
        }

        if let preference = result.preferredMfaSetting {
            preferred = MFAType(rawValue: preference)
        }

        return .init(enabled: enabledList, preferred: preferred)
    }
}
