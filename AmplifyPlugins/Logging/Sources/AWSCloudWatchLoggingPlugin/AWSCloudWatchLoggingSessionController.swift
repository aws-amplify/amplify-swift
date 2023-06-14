//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPluginsCore
import Amplify
import Combine
import Foundation
import AWSCloudWatchLogs
import AWSClientRuntime

/// Responsible for setting up and tearing-down log sessions for a given category/tag according to changes in
/// user authentication sessions.
///
/// - Tag: CloudWatchLogSessionController
final class AWSCloudWatchLoggingSessionController {
    
    let logGroupName: String
    let region: String
    
    var logLevel: LogLevel {
        didSet {
            self.session?.logger.logLevel = logLevel
        }
    }
    private var client: CloudWatchLogsClientProtocol?
    private let credentialsProvider: CredentialsProvider
    private let authentication: AuthCategoryUserBehavior
    private let tag: String
    private var session: AWSCloudWatchLoggingSession?
    private var consumer: LogBatchConsumer?
    private var batchSubscription: AnyCancellable? { willSet { batchSubscription?.cancel() } }
    private var authSubscription: AnyCancellable? { willSet { authSubscription?.cancel() } }
    private var userIdentifier: String? {
        didSet {
            if oldValue != userIdentifier {
                userIdentifierDidChange()
            }
        }
    }

    /// - Tag: CloudWatchLogSessionController.init
    init(credentialsProvider: CredentialsProvider,
         authentication: AuthCategoryUserBehavior,
         tag: String,
         logLevel: LogLevel,
         logGroupName: String,
         region: String
    ) {
        self.credentialsProvider = credentialsProvider
        self.authentication = authentication
        self.tag = tag
        self.logLevel = logLevel
        self.logGroupName = logGroupName
        self.region = region
    }
    
    func enable() {
        let channel = Amplify.Hub.publisher(for: .auth)
        self.authSubscription = channel.sink { [weak self] payload in
            self?.handle(payload: payload)
        }
        updateSession()
        updateConsumer()
        connectProducerAndConsumer()
    }
    
    func disable() {
        self.batchSubscription = nil
        self.authSubscription = nil
        self.session = nil
        self.consumer = nil
    }

    private func updateConsumer() {
        do {
            self.consumer = try createConsumer()
        } catch {
            self.consumer = nil
        }
    }

    private func createConsumer() throws -> LogBatchConsumer? {
        if self.client == nil {
            let configuration = try CloudWatchLogsClient.CloudWatchLogsClientConfiguration(
                credentialsProvider: credentialsProvider,
                region: region
            )
            self.client = CloudWatchLogsClient(config: configuration)
        }

        guard let cloudWatchClient = client else { return nil }
        return try CloudWatchLoggingConsumer(client: cloudWatchClient,
                                             logGroupName: self.logGroupName,
                                             userIdentifier: self.userIdentifier)
    }
    
    private func connectProducerAndConsumer() {
        guard let consumer = consumer else {
            self.batchSubscription = nil
            return
        }
        guard let producer = session else {
            self.batchSubscription = nil
            return
        }
        self.batchSubscription = producer.logBatchPublisher.sink { batch in
            Task {
                do {
                    try await consumer.consume(batch: batch)
                } catch {
                    print(error)
                }
            }
        }
    }
    
    private func userIdentifierDidChange() {
        updateSession()
        updateConsumer()
        connectProducerAndConsumer()
    }
    
    private func updateSession() {
        do {
            self.session = try AWSCloudWatchLoggingSession(tag: self.tag,
                                                    logLevel: self.logLevel,
                                                    userIdentifier: self.userIdentifier)
        } catch {
            self.session = nil
            print(error)
        }
    }
    
    private func handle(payload: HubPayload) {
        enum CognitoEventName: String {
            case signInAPI = "Auth.signInAPI"
            case signOutAPI = "Auth.signOutAPI"
        }
        switch payload.eventName {
        case HubPayload.EventName.Auth.signedIn, CognitoEventName.signInAPI.rawValue:
            takeUserIdentifierFromCurrentUser()
        case HubPayload.EventName.Auth.signedOut, CognitoEventName.signOutAPI.rawValue:
            self.userIdentifier = nil
        default:
            break
        }
    }
    
    func takeUserIdentifierFromCurrentUser() {
        Task {
            do {
                let user = try await authentication.getCurrentUser()
                self.userIdentifier = user.userId
            } catch {
                self.userIdentifier = nil
            }
        }
    }
    
}

extension AWSCloudWatchLoggingSessionController: Logger {
    func error(_ message: @autoclosure () -> String) {
        session?.logger.error(message())
    }
    
    func error(error: Error) {
        session?.logger.error(error: error)
    }
    
    func warn(_ message: @autoclosure () -> String) {
        session?.logger.warn(message())
    }
    
    func info(_ message: @autoclosure () -> String) {
        session?.logger.info(message())
    }
    
    func debug(_ message: @autoclosure () -> String) {
        session?.logger.debug(message())
    }
    
    func verbose(_ message: @autoclosure () -> String) {
        session?.logger.verbose(message())
    }
}
