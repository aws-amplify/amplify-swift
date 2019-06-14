////
//// Copyright 2018-2019 Amazon.com,
//// Inc. or its affiliates. All Rights Reserved.
////
//// SPDX-License-Identifier: Apache-2.0
////
//
//import Foundation
//
///// A queue to hold incoming subscription messages and deliver them to the caller
//final class HubMessageQueue {
//
//    /// Serial dispatch queue to ensure thread safety
//    private let syncQueue: DispatchQueue
//
//    /// Serial OperationQueue for invoking resultHandler. Uses Global queue as its backing queue
//    private let deliveryQueue: OperationQueue
//
//    /// The handler function to invoke upon receipt of a subscription message
//    private let resultHandler: ResultHandler
//
//    /// A queue of messages to be delivered
//    private var messagesQueue = [HubPayload]()
//
//    /// `true` if the queue is currently delivering messages; `false` if delivery is paused
//    private var isDelivering = false
//
//    init(for operationId: String, resultHandler: @escaping ResultHandler) {
//        self.resultHandler = resultHandler
//
//        syncQueue = DispatchQueue(label: "SubscriptionMessagesQueue.sync.\(operationId)")
//
//        deliveryQueue = OperationQueue()
//        deliveryQueue.maxConcurrentOperationCount = 1
//        deliveryQueue.underlyingQueue = DispatchQueue.global()
//        deliveryQueue.name = "SubscriptionMessagesQueue.delivery.\(operationId)"
//    }
//
//    /// Adds a result to the queue for delivery. As an optimization, if the queue is currently delivering
//    /// (that is, if `startDelivery` has been invoked), and if `messagesQueue` is empty, immediately invokes
//    /// the result handler with the result, rather than queuing it.
//    ///
//    /// `resultHandler` will be invoked asynchronously on the global background queue.
//    ///
//    /// - Parameters:
//    ///   - subscriptionResult: The result to add or deliver
//    ///   - transaction: An optional ReadWriteTransaction that generated the result. If `subscriptionResult` is
//    ///     eligible for immediate delivery, this transaction will be passed along. Otherwise, it is the
//    ///     responsibility of `resultHandler` to provide an appropriate transaction context to its caller.
//    func append(_ result: GraphQLResult<Subscription.Data>, transaction: ApolloStore.ReadWriteTransaction?) {
//        let item = QueueItem(result: result, date: Date())
//        syncQueue.sync {
//            if isDelivering && messagesQueue.isEmpty {
//                AppSyncLog.debug("Immediately delivering subscription message")
//                deliver(item, transaction: transaction)
//            } else {
//                AppSyncLog.debug("Appending subscription message to queue")
//                messagesQueue.append(item)
//            }
//        }
//    }
//
//    /// Enables delivery of queue items. Internally, this drains the current queue and invokes the result handler
//    /// for each queued item, then enables immediate delivery for newly-queued items.
//    func startDelivery() {
//        syncQueue.sync {
//            drainQueue()
//            isDelivering = true
//        }
//    }
//
//    /// Stops delivery of queue items. Items enqueued with `add` will be stored for processing, pending a
//    /// subsequent call to `startDelivery`.
//    ///
//    /// Invoking this method does not cancel delivery of in-process items, but rather prevents newly-queued
//    /// items from being delivered.
//    func stopDelivery() {
//        syncQueue.sync {
//            isDelivering = false
//        }
//    }
//
//    /// Iterates over the message queue and delivers each message, then clears the queue. Note that this blocks
//    /// the addition of new items to the queue while it is processing, but since `resultHandler` is invoked
//    /// asynchronously on the global queue, the practical impact should be relatively small.
//    ///
//    /// Note: this method must only be invoked from a `syncQueue.sync` block, as it mutates the messages queue.
//    private func drainQueue() {
//        for queueItem in messagesQueue {
//            deliver(queueItem)
//        }
//        messagesQueue = []
//    }
//
//    /// Asynchronously invokes the resultHandler for `item` on the global queue
//    private func deliver(_ item: QueueItem, transaction: ApolloStore.ReadWriteTransaction? = nil) {
//        deliveryQueue.addOperation {
//            self.resultHandler(item.result, item.date, transaction)
//        }
//    }
//}
//
//struct SubscriptionMessagesQueueItem<Subscription: GraphQLSubscription> {
//    let result: GraphQLResult<Subscription.Data>
//    let date: Date
//}
