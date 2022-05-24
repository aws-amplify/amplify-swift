//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import UIKit

class SessionTracker: InternalPinpointClient {
    private var session: PinpointSession? = nil
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var backgroundTimer: Timer? = nil {
        willSet {
            backgroundTimer?.invalidate()
        }
    }

    override init(context: PinpointContext) {
        if let sessionData = context.userDefaults.data(forKey: Constants.sessionKey) {
            session = try? NSKeyedUnarchiver.unarchivedObject(ofClass: PinpointSession.self, from: sessionData)
        }
        super.init(context: context)
    }

    var currentSession: PinpointSession {
        if let session = session {
            return session
        }

        return createNewSession()
    }

    func startSession() async throws -> PinpointSession {
        try await endCurrentSession()
        return createNewSession()
    }

    func stopSession() async throws {
        guard session != nil else {
            Amplify.Analytics.log.debug("Session Stop Failed: No session is running.")
            return
        }
        try await endCurrentSession()
    }

    func resumeSession() async throws {
        guard let stopTime = currentSession.stopTime?.timeIntervalSince1970 else {
            Amplify.Analytics.log.verbose("Session Resume Failed: Session is already runnning.")
            return
        }
        
        let now = Date().timeIntervalSince1970
        if now - stopTime < context.configuration.sessionTimeout {
            try await resumeCurrentSession()
        } else {
            Amplify.Analytics.log.verbose("Session has expired. Starting a fresh one...")
            try await endCurrentSession()
            _ = createNewSession()
        }
    }

    private func createNewSession() -> PinpointSession {
        backgroundTimer = nil
        let session = PinpointSession(appId: context.configuration.appId,
                                      uniqueId: context.uniqueId)
        save(session: session)
        let startEvent = context.analyticsClient.createEvent(withEventType: Constants.Events.start)

        // Update Endpoint and record Session Start event
        Task {
            try? await context.targetingClient.updateEndpointProfile()
            try? await context.analyticsClient.record(startEvent)
        }
        return session
    }

    private func save(session: PinpointSession) {
        self.session = session
        do {
            let sessionData = try NSKeyedArchiver.archivedData(withRootObject: session,
                                                               requiringSecureCoding: true)
            context.userDefaults.set(sessionData, forKey: Constants.sessionKey)
        } catch {
            Amplify.Analytics.log.error("Error archiving sessionData: \(error.localizedDescription)")
        }
    }

    private func resumeCurrentSession() async throws {
        backgroundTimer = nil

        guard let session = session else {
            return
        }
        session.resume()
        save(session: session)

        let resumeEvent = context.analyticsClient.createEvent(withEventType: Constants.Events.resume)
        return try await context.analyticsClient.record(resumeEvent)
    }

    private func endCurrentSession() async throws {
        backgroundTimer = nil
        
        guard session != nil else { return }
        session?.pause()

        Amplify.Analytics.log.verbose("Firing Session Event: Stop")
        let stopEvent = context.analyticsClient.createEvent(withEventType: Constants.Events.stop)
        Amplify.Analytics.log.info("Session Stopped.")
        session = nil
        
        // Remove Global Event Source Attributes
        return try await context.analyticsClient.record(stopEvent)
    }
    
    private func startBackgroundTimeout() {
        let sessionTimeout = context.configuration.sessionTimeout
        if sessionTimeout > 0 {
            backgroundTask = UIApplication.shared.beginBackgroundTask(withName: Constants.backgroundTask) { [weak self] in
                self?.handleBackgroundTimeout()
            }
        }
        
        backgroundTimer = Timer.scheduledTimer(withTimeInterval: sessionTimeout, repeats: false) { [weak self] _ in
            self?.handleBackgroundTimeout()
        }
    }
    
    private func handleBackgroundTimeout() {
        Task {
            try? await endCurrentSession()
            _ = try? await context.analyticsClient.submitEvents()
            endBackgroundTask()
        }
    }
    
    private func endBackgroundTask() {
        guard backgroundTask != .invalid else {
            return
        }
        
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }
}

extension SessionTracker {
    struct Constants {
        static let sessionKey = "com.amazonaws.AWSPinpointSessionKey"
        static let backgroundTask = "com.amazonaws.AWSPinpointSessionBackgroundTask"
        
        struct Events {
            static let start = "_session.start"
            static let stop = "_session.stop"
            static let pause = "_session.pause"
            static let resume = "_session.resume"
        }
    }
}
