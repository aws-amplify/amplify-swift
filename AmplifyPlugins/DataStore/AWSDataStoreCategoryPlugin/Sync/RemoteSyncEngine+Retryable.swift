//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// All methods in this extension must be invoked from workQueue (as in during a `respond` call
extension RemoteSyncEngine {

    func resetCurrentAttemptNumber() {
        currentAttemptNumber = 1
    }

    func scheduleRestartOrTerminate(error: AmplifyError) {
        let advice = getRetryAdvice(error: error)
        if advice.shouldRetry {
            scheduleRestart(advice: advice)
        } else {
            remoteSyncTopicPublisher.send(completion: .failure(DataStoreError.api(error)))
            if let completionBlock = finishedCompletionBlock {
                completionBlock(.failure(causedBy: error))
                finishedCompletionBlock = nil
            }
        }
    }

    private func getRetryAdvice(error: Error) -> RequestRetryAdvice {
        //TODO: Parse error from the receive completion to use as an input into getting retry advice.
        //      For now, specifying not connected to internet to force a retry up to our maximum
        let urlError = URLError(.notConnectedToInternet)
        let advice = requestRetryablePolicy.retryRequestAdvice(urlError: urlError,
                                                               httpURLResponse: nil,
                                                               attemptNumber: currentAttemptNumber)
        return advice
    }

    private func scheduleRestart(advice: RequestRetryAdvice) {
        log.verbose("\(#function) scheduling retry for restarting remote sync engine")
        resolveReachabilityPublisher()
        mutationRetryNotifier = MutationRetryNotifier(
            advice: advice,
            networkReachabilityPublisher: networkReachabilityPublisher
        ) {
            self.workQueue.async {
                self.mutationRetryNotifier = nil
                self.stateMachine.notify(action: .scheduledRestartTriggered)
            }
        }
        currentAttemptNumber += 1
    }

    private func resolveReachabilityPublisher() {
        if networkReachabilityPublisher == nil {
            if let reachability = api as? APICategoryReachabilityBehavior {
                do {
                    networkReachabilityPublisher = try reachability.reachabilityPublisher()
                } catch {
                    log.error("\(#function): Unable to listen on reachability: \(error)")
                }
            }
        }
    }
}
