//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

@available(iOS 13.0, *)
extension RemoteSyncEngine {

    func resetCurrentAttemptNumber() {
        currentAttemptNumber = 1
    }

    func scheduleRestart(error: AmplifyError?) {
        let advice = getRetryAdviceIfRetryable(error: error)
        if advice.shouldRetry {
            scheduleRestart(advice: advice)
        } else {
            if let error = error {
                remoteSyncTopicPublisher.send(completion: .failure(DataStoreError.api(error)))
            } else {
                remoteSyncTopicPublisher.send(completion: .finished)
            }
        }

    }

    private func getRetryAdviceIfRetryable(error: Error?) -> RequestRetryAdvice {
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
        mutationRetryNotifier = MutationRetryNotifier(advice: advice,
                                                      networkReachabilityPublisher: networkReachabilityPublisher) {
                                                        self.mutationRetryNotifier = nil
                                                        self.stateMachine.notify(action: .receivedStart)
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
