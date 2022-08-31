//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

class AWSAuthTaskHelper {

    private var stateMachineToken: AuthStateMachineToken?
    private let authStateMachine: AuthStateMachine

    init(stateMachineToken: AuthStateMachineToken?,
         authStateMachine: AuthStateMachine) {
        self.stateMachineToken = stateMachineToken
        self.authStateMachine = authStateMachine
    }

    func didStateMachineConfigured() async {
        await withCheckedContinuation { [weak self] (continuation: CheckedContinuation<Void, Never>) in
            stateMachineToken = authStateMachine.listen({ [weak self] state in
                guard let self = self, case .configured = state else { return }
                self.cancelToken()
                continuation.resume()
            }, onSubscribe: {})
        }
    }

    private func cancelToken() {
        if let token = stateMachineToken {
            authStateMachine.cancel(listenerToken: token)
        }
    }

}
