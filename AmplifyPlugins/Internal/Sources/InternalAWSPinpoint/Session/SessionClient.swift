//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

@_spi(InternalAWSPinpoint)
public protocol SessionClientBehaviour: AnyObject {
    var currentSession: PinpointSession { get }
    var analyticsClient: AnalyticsClientBehaviour? { get set }

    func startPinpointSession()
    func validateOrRetrieveSession(_ session: PinpointSession?) -> PinpointSession
    func startTrackingSessions(backgroundTimeout: TimeInterval)
}

struct SessionClientConfiguration {
    let appId: String
    let uniqueDeviceId: String
}

class SessionClient: SessionClientBehaviour {
    private var session: PinpointSession

    weak var analyticsClient: AnalyticsClientBehaviour?
    private let endpointClient: EndpointClientBehaviour

    private let activityTracker: ActivityTrackerBehaviour
    private let archiver: AmplifyArchiverBehaviour
    private let configuration: SessionClientConfiguration
    private let sessionClientQueue = DispatchQueue(label: Constants.queue,
                                                   attributes: .concurrent)
    private let userDefaults: UserDefaultsBehaviour
    private var sessionBackgroundTimeout: TimeInterval = .zero

    init(activityTracker: ActivityTrackerBehaviour = ActivityTracker(),
         analyticsClient: AnalyticsClientBehaviour? = nil,
         archiver: AmplifyArchiverBehaviour,
         configuration: SessionClientConfiguration,
         endpointClient: EndpointClientBehaviour,
         userDefaults: UserDefaultsBehaviour) {
        self.activityTracker = activityTracker
        self.analyticsClient = analyticsClient
        self.archiver = archiver
        self.configuration = configuration
        self.endpointClient = endpointClient
        self.userDefaults = userDefaults
        session = Self.retrieveStoredSession(from: userDefaults, using: archiver) ?? PinpointSession.invalid
    }

    var currentSession: PinpointSession {
        if session == PinpointSession.invalid {
            startNewSession()
        }
        return session
    }

    func startPinpointSession() {
        guard analyticsClient != nil else {
            log.error("Pinpoint Analytics is disabled.")
            return
        }

        sessionClientQueue.sync(flags: .barrier) {
            if session != PinpointSession.invalid {
                endSession()
            }
            startNewSession()
        }
    }
    
    func startTrackingSessions(backgroundTimeout: TimeInterval) {
        sessionBackgroundTimeout = backgroundTimeout
        activityTracker.backgroundTrackingTimeout = backgroundTimeout
        activityTracker.beginActivityTracking { [weak self] newState in
            guard let self = self else { return }
            self.log.verbose("New state received: \(newState)")
            self.sessionClientQueue.sync(flags: .barrier) {
                self.respond(to: newState)
            }
        }
    }

    func validateOrRetrieveSession(_ session: PinpointSession?) -> PinpointSession {
        if let session = session, !session.sessionId.isEmpty {
            return session
        }

        if let storedSession = Self.retrieveStoredSession(from: userDefaults, using: archiver) {
            return storedSession
        }

        return PinpointSession(sessionId: PinpointSession.Constants.defaultSessionId,
                               startTime: Date(),
                               stopTime: Date())
    }

    private static func retrieveStoredSession(from userDefaults: UserDefaultsBehaviour,
                                              using archiver: AmplifyArchiverBehaviour) -> PinpointSession? {
        guard let sessionData = userDefaults.data(forKey: Constants.sessionKey),
              let storedSession = try? archiver.decode(PinpointSession.self, from: sessionData),
              !storedSession.sessionId.isEmpty else {
            return nil
        }

        return storedSession
    }

    private func startNewSession() {
        session = PinpointSession(appId: configuration.appId,
                                  uniqueId: configuration.uniqueDeviceId)
        saveSession()
        log.info("Session Started.")

        // Update Endpoint and record Session Start event
        Task {
            try? await endpointClient.updateEndpointProfile()
            log.verbose("Firing Session Event: Start")
            record(eventType: Constants.Events.start)
        }
    }

    private func saveSession() {
        do {
            let sessionData = try archiver.encode(session)
            userDefaults.save(sessionData, forKey: Constants.sessionKey)
        } catch {
            log.error("Error archiving sessionData: \(error.localizedDescription)")
        }
    }

    private func pauseSession() {
        session.pause()
        saveSession()
        log.info("Session Paused.")
        log.verbose("Firing Session Event: Pause")
        record(eventType: Constants.Events.pause)
    }

    private func resumeSession() {
        guard session.isPaused else {
            log.verbose("Session Resume Failed: Session is already runnning.")
            return
        }

        guard !isSessionExpired(session) else {
            log.verbose("Session has expired. Starting a fresh one...")
            endSession()
            startNewSession()
            return
        }

        session.resume()
        saveSession()
        log.info("Session Resumed.")

        log.verbose("Firing Session Event: Resume")
        record(eventType: Constants.Events.resume)
    }

    private func endSession() {
        session.stop()
        log.info("Session Stopped.")

        Task {
            log.verbose("Removing remote global attributes")
            await analyticsClient?.removeAllRemoteGlobalAttributes()
            log.verbose("Firing Session Event: Stop")
            record(eventType: Constants.Events.stop)
        }
    }

    private func isSessionExpired(_ session: PinpointSession) -> Bool {
        guard let stopTime = session.stopTime?.timeIntervalSince1970 else {
            return false
        }

        let now = Date().timeIntervalSince1970
        return now - stopTime > sessionBackgroundTimeout
    }

    private func record(eventType: String) {
        guard let analyticsClient = analyticsClient else {
            log.error("Pinpoint Analytics is disabled.")
            return
        }

        let event = analyticsClient.createEvent(withEventType: eventType)
        Task {
            try? await analyticsClient.record(event)
        }
    }

    private func respond(to newState: ApplicationState) {
        switch newState {
        case .terminated:
            endSession()
    #if !os(macOS)
        case .runningInBackground(let isStale):
            if isStale {
                endSession()
                Task {
                    try? await analyticsClient?.submitEvents()
                }
            } else {
                pauseSession()
            }
        case .runningInForeground:
            resumeSession()
    #endif
        default:
            break
        }
    }
}

// MARK: - DefaultLogger
extension SessionClient: DefaultLogger {
    public static var log: Logger {
        Amplify.Logging.logger(forCategory: CategoryType.analytics.displayName)
    }
    public var log: Logger {
        Self.log
    }
}

extension SessionClient {
    struct Constants {
        static let sessionKey = "com.amazonaws.AWSPinpointSessionKey"
        static let queue = "com.amazonaws.Amplify.SessionClientQueue"

        struct Events {
            static let start = "_session.start"
            static let stop = "_session.stop"
            static let pause = "_session.pause"
            static let resume = "_session.resume"
        }
    }
}

extension PinpointSession {
    static var invalid = PinpointSession(sessionId: "InvalidId", startTime: Date(), stopTime: nil)
}
