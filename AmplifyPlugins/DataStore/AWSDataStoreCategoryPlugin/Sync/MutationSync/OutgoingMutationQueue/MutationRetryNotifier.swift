//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSPluginsCore
import Combine

@available(iOS 13.0, *)
final class MutationRetryNotifier {
    private var nextSyncTimer: DispatchSourceTimer?
    private var handlerQueue = DispatchQueue.global(qos: .default)
    var retryMutationCallback: () -> Void
    private var reachabilitySubscription: Subscription?

    init(advice: RequestRetryAdvice,
         networkReachabilityPublisher: AnyPublisher<ReachabilityUpdate, Never>?,
         retryMutationCallback: @escaping BasicClosure) {
        self.retryMutationCallback = retryMutationCallback

        let deadline = DispatchTime.now() + advice.retryInterval
        scheduleTimer(at: deadline)

        networkReachabilityPublisher?.dropFirst().subscribe(self)
    }

    deinit {
        cancel()
    }

    private func scheduleTimer(at deadline: DispatchTime) {
        nextSyncTimer = DispatchSource.makeOneOffDispatchSourceTimer(deadline: deadline, queue: handlerQueue) {
            self.notifyCallback()
        }
        nextSyncTimer?.resume()
    }

    func cancel() {
        reachabilitySubscription?.cancel()
        nextSyncTimer?.cancel()
    }

    func notifyCallback() {
        // Call the cancel routine as the purpose of retry is fulfilled
        cancel()
        retryMutationCallback()
    }
}

@available(iOS 13.0, *)
extension MutationRetryNotifier: Subscriber {
    func receive(subscription: Subscription) {
        log.verbose(#function)
        reachabilitySubscription = subscription
        subscription.request(.unlimited)
    }

    func receive(_ reachabilityUpdate: ReachabilityUpdate) -> Subscribers.Demand {
        if reachabilityUpdate.isOnline {
            notifyCallback()
            return .none
        }
        return .unlimited
    }

    func receive(completion: Subscribers.Completion<Never>) {
        log.verbose(#function)
        reachabilitySubscription?.cancel()
    }
}

@available(iOS 13.0, *)
extension MutationRetryNotifier: DefaultLogger { }
