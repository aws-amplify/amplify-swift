//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore
import AWSCognitoIdentityProvider

class AWSAuthTaskHelper {

    private let authStateMachine: AuthStateMachine
    private let fetchAuthSessionHelper: FetchAuthSessionOperationHelper

    init(authStateMachine: AuthStateMachine) {
        self.authStateMachine = authStateMachine
        self.fetchAuthSessionHelper = FetchAuthSessionOperationHelper()
    }

    func didStateMachineConfigured() async {
        let stateSequences = await authStateMachine.listen()
        for await state in stateSequences {
            if case .configured = state { return }
        }
    }

    func getAccessToken() async throws -> String {

        let session = try await fetchAuthSessionHelper.fetch(authStateMachine)
        guard let cognitoTokenProvider = session as? AuthCognitoTokensProvider else {
            throw AuthError.unknown("Unable to fetch auth session", nil)
        }

        do {
            let tokens = try cognitoTokenProvider.getCognitoTokens().get()
            return tokens.accessToken
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.unknown("Unable to fetch auth session", error)
        }
    }

}
