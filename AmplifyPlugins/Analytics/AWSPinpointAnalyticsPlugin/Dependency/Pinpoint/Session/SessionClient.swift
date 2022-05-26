//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

class SessionClient: InternalPinpointClient {
    private let archiver: AmplifyArchiverBehaviour
    private let activityTracker: ActivityTracker
    private var session: PinpointSession

    init(context: PinpointContext,
         archiver: AmplifyArchiverBehaviour = AmplifyArchiver()) {
        activityTracker = ActivityTracker(timeout: context.configuration.sessionTimeout)
        self.archiver = archiver
        session = PinpointSession(appId: context.configuration.appId,
                                  uniqueId: context.uniqueId)
        super.init(context: context)
        startSession()
    }

    var currentSession: PinpointSession {
        if !session.sessionId.isEmpty {
            return session
        }
        
        if let sessionData = context.userDefaults.data(forKey: Constants.sessionKey),
           let storedSession = try? archiver.decode(PinpointSession.self, from: sessionData),
           !storedSession.sessionId.isEmpty {
            return storedSession
        }
        
        return PinpointSession(sessionId: PinpointSession.Constants.defaultSessionId,
                               startTime: Date(),
                               stopTime: Date())
    }

    private func startSession() {
        saveSession()
        Amplify.Analytics.log.info("Session Started.")
        activityTracker.delegate = self
        activityTracker.beginActivityTracking()

        let startEvent = context.analyticsClient.createEvent(withEventType: Constants.Events.start)
        // Update Endpoint and record Session Start event
        Task {
            try? await context.targetingClient.updateEndpointProfile()
            Amplify.Analytics.log.verbose("Firing Session Event: Start")
            try? await context.analyticsClient.record(startEvent)
        }
    }

    private func saveSession() {
        do {
            let sessionData = try archiver.encode(session)
            context.userDefaults.save(sessionData, forKey: Constants.sessionKey)
        } catch {
            Amplify.Analytics.log.error("Error archiving sessionData: \(error.localizedDescription)")
        }
    }
    
    private func pauseSession() {
        session.pause()
        saveSession()
        Amplify.Analytics.log.info("Session Paused.")

        let pauseEvent = context.analyticsClient.createEvent(withEventType: Constants.Events.pause)
        Task {
            Amplify.Analytics.log.verbose("Firing Session Event: Pause")
            try? await context.analyticsClient.record(pauseEvent)
        }
    }
    
    private func resumeSession() {
        guard session.isPaused else {
            Amplify.Analytics.log.verbose("Session Resume Failed: Session is already runnning.")
            return
        }
        
        guard !isSessionExpired(session) else {
            Amplify.Analytics.log.verbose("Session has expired. Starting a fresh one...")
            endSession()
            session = PinpointSession(appId: context.configuration.appId,
                                      uniqueId: context.uniqueId)
            startSession()
            return
        }
        
        session.resume()
        saveSession()
        Amplify.Analytics.log.info("Session Resumed.")

        let resumeEvent = context.analyticsClient.createEvent(withEventType: Constants.Events.resume)
        Task {
            Amplify.Analytics.log.verbose("Firing Session Event: Resume")
            try? await context.analyticsClient.record(resumeEvent)
        }
    }
    
    private func endSession() {
        session.stop()
        Amplify.Analytics.log.info("Session Stopped.")

        // TODO: Remove Global Event Source Attributes

        let stopEvent = context.analyticsClient.createEvent(withEventType: Constants.Events.stop)
        Task {
            Amplify.Analytics.log.verbose("Firing Session Event: Stop")
            try? await context.analyticsClient.record(stopEvent)
        }
    }
    
    private func isSessionExpired(_ session: PinpointSession) -> Bool {
        guard let stopTime = session.stopTime?.timeIntervalSince1970 else {
            return false
        }
        
        let now = Date().timeIntervalSince1970
        return now - stopTime < context.configuration.sessionTimeout
    }
}

// MARK: - ActivityTrackerDelegate
extension SessionClient: ActivityTrackerDelegate {
    func appDidMoveToBackground() {
        pauseSession()
    }
    
    func appDidMoveToForeground() {
        resumeSession()
    }
    
    func appWillTerminate() {
        endSession()
    }
    
    func backgroundTrackingDidTimeout() {
        endSession()
        Task {
            try? await context.analyticsClient.submitEvents()
        }
    }
}

extension SessionClient {
    struct Constants {
        static let sessionKey = "com.amazonaws.AWSPinpointSessionKey"
        
        struct Events {
            static let start = "_session.start"
            static let stop = "_session.stop"
            static let pause = "_session.pause"
            static let resume = "_session.resume"
        }
    }
}
